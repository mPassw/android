package com.example.mpass

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.app.assist.AssistStructure
import android.app.slice.Slice
import android.app.slice.SliceSpec
import android.content.Intent
import android.content.res.Resources
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.service.autofill.AutofillService
import android.service.autofill.Dataset
import android.service.autofill.FillCallback
import android.service.autofill.FillRequest
import android.service.autofill.FillResponse
import android.service.autofill.InlinePresentation
import android.service.autofill.SaveCallback
import android.service.autofill.SaveInfo
import android.service.autofill.SaveRequest
import android.util.Log
import android.util.Size
import android.util.TypedValue
import android.view.autofill.AutofillId
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import android.widget.inline.InlinePresentationSpec
import androidx.annotation.RequiresApi
import androidx.autofill.inline.v1.InlineSuggestionUi
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel

class MpassAutofillService : AutofillService() {

    private lateinit var flutterEngine: FlutterEngine
    private lateinit var methodChannel: MethodChannel
    private var currentRequest: FillRequest? = null

    companion object {
        private const val TAG = "MpassAutofillService"
        private const val MPASS_PACKAGE_NAME = "com.example.mpass"
        private const val METHOD_CHANNEL_NAME = "com.example.mpass_autofill"
        private const val DART_ENTRYPOINT = "autofillMain"

        private val BROWSER_PACKAGES = listOf(
            "com.android.chrome",
            "org.mozilla.firefox",
            "com.opera.browser",
            "com.brave.browser",
            "com.microsoft.emmx",
            "com.google.android.apps.chrome",
            "com.sec.android.app.sbrowser",  // Samsung browser
            "com.duckduckgo.mobile.android", // DuckDuckGo
            "com.UCMobile.intl",             // UC Browser
            "com.vivaldi.browser",           // Vivaldi
            "org.torproject.torbrowser"      // Tor Browser
        )
    }

    override fun onCreate() {
        super.onCreate()

        val flutterLoader = FlutterLoader()
        flutterLoader.startInitialization(this)
        flutterLoader.ensureInitializationComplete(this, null)

        flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                flutterLoader.findAppBundlePath(),
                DART_ENTRYPOINT
            )
        )
        methodChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME)
    }

    override fun onFillRequest(
        request: FillRequest,
        cancellationSignal: CancellationSignal,
        callback: FillCallback
    ) {
        val fillContexts = request.fillContexts
        if (fillContexts.isEmpty()) {
            callback.onFailure("No fill contexts available")
            return
        }

        currentRequest = request

        val structure = fillContexts.last().structure
        val requestingPackage = structure.activityComponent?.packageName ?: ""

        if (requestingPackage == MPASS_PACKAGE_NAME) {
            callback.onSuccess(null)
            return
        }

        val autofillableFields = findAutofillableFields(structure)

        if (autofillableFields.isEmpty()) {
            callback.onSuccess(null)
            return
        }

        val usernameAutofillId =
            autofillableFields.entries.filter { it.value == FieldType.USERNAME }.map { it.key }
                .toTypedArray()
        val passwordAutofillId =
            autofillableFields.entries.filter { it.value == FieldType.PASSWORD }.map { it.key }
                .toTypedArray()

        if (usernameAutofillId.isEmpty() && passwordAutofillId.isEmpty()) {
            callback.onSuccess(null)
            return
        }

        var webDomain: String? = null
        var formUrl: String? = null

        if (BROWSER_PACKAGES.contains(requestingPackage)) {
            val urlInfo = extractUrlFromBrowser(structure)
            webDomain = urlInfo.first
            formUrl = urlInfo.second
        }

        // Build request parameters for Flutter
        val requestParams = mutableMapOf<String, Any?>(
            "requestingPackage" to requestingPackage
        )

        // Add web domain if available
        if (webDomain != null) {
            requestParams["webDomain"] = webDomain
        }
        if (formUrl != null) {
            requestParams["formUrl"] = formUrl
        }

        methodChannel.invokeMethod(
            "getPasswordsList",
            requestParams,
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    val passwords = result as? List<Map<String, Any>>

                    if (passwords.isNullOrEmpty()) {
                        callback.onSuccess(null)
                        return
                    }

                    val responseBuilder = FillResponse.Builder()

                    passwords.forEach { password ->
                        val passwordId = password["id"] as? String ?: ""
                        val title = password["title"] as? String ?: "Unknown"

                        try {
                            responseBuilder.addDataset(
                                createDataset(
                                    title,
                                    passwordId,
                                    usernameAutofillId,
                                    passwordAutofillId,
                                    webDomain,
                                    formUrl
                                )
                            )
                        } catch (_: Exception) {
                        }
                    }

                    try {
                        responseBuilder.addDataset(
                            createDataset(
                                "Choose from mPass",
                                null,
                                usernameAutofillId,
                                passwordAutofillId,
                                null,
                                null
                            )
                        )
                    } catch (_: Exception) {
                    }

                    addSaveInfo(
                        responseBuilder,
                        autofillableFields,
                        webDomain,
                        formUrl,
                    )

                    try {
                        callback.onSuccess(responseBuilder.build())
                    } catch (e: Exception) {
                        callback.onSuccess(null)
                    }
                }

                override fun error(code: String, message: String?, details: Any?) {
                    callback.onSuccess(null)
                }

                override fun notImplemented() {
                    callback.onSuccess(null)
                }
            })
    }

    fun createDataset(
        title: String,
        passwordId: String?,
        usernameAutofillId: Array<AutofillId>,
        passwordAutofillId: Array<AutofillId>,
        webDomain: String?,
        formUrl: String?
    ): Dataset {
        // Create a presentation view for this dataset
        val presentation = createDatasetPresentation(title)

        // Build a dataset with the authentication intent
        val datasetBuilder = Dataset.Builder(presentation)

        Log.d("Dataset", Build.VERSION.SDK_INT.toString())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val inlinePresentation = createInlinePresentation(
                title,
                passwordId,
                usernameAutofillId,
                passwordAutofillId,
                webDomain,
                formUrl
            )
            if (inlinePresentation != null) {
                datasetBuilder.setInlinePresentation(inlinePresentation)
            }
        }
        usernameAutofillId.forEach { autofillId ->
            datasetBuilder.setValue(
                autofillId,
                AutofillValue.forText("")
            )
        }
        passwordAutofillId.forEach { autofillId ->
            datasetBuilder.setValue(
                autofillId,
                AutofillValue.forText("")
            )
        }

        // Create an intent to launch the authentication activity
        val authIntent = Intent(
            this@MpassAutofillService, AuthenticationActivity::class.java
        ).apply {
            putExtra(
                AuthenticationActivity.EXTRA_USERNAME_AUTOFILL_ID,
                usernameAutofillId
            )
            putExtra(
                AuthenticationActivity.EXTRA_PASSWORD_AUTOFILL_ID,
                passwordAutofillId
            )
            if (passwordId != null) {
                putExtra(AuthenticationActivity.EXTRA_PASSWORD_ID, passwordId)
            }
            if (webDomain != null) {
                putExtra("EXTRA_WEB_DOMAIN", webDomain)
            }
            if (formUrl != null) {
                putExtra("EXTRA_FORM_URL", formUrl)
            }
        }

        val requestCode = passwordId.hashCode()

        val pendingIntent = PendingIntent.getActivity(
            this@MpassAutofillService,
            requestCode,
            authIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        datasetBuilder.setAuthentication(pendingIntent.intentSender)
    
        return datasetBuilder.build()
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun createInlinePresentation(
        title: String,
        passwordId: String?,
        usernameAutofillId: Array<AutofillId>,
        passwordAutofillId: Array<AutofillId>,
        webDomain: String?,
        formUrl: String?
    ): InlinePresentation? {
        // 1. Create authentication intent
        val authIntent = Intent(this, AuthenticationActivity::class.java).apply {
            putExtra(AuthenticationActivity.EXTRA_USERNAME_AUTOFILL_ID, usernameAutofillId)
            putExtra(AuthenticationActivity.EXTRA_PASSWORD_AUTOFILL_ID, passwordAutofillId)
            passwordId?.let { putExtra(AuthenticationActivity.EXTRA_PASSWORD_ID, it) }
            webDomain?.let { putExtra("EXTRA_WEB_DOMAIN", it) }
            formUrl?.let { putExtra("EXTRA_FORM_URL", it) }
        }

        // 2. Create pending intent
        val pendingIntent = PendingIntent.getActivity(
            this,
            passwordId?.hashCode() ?: System.currentTimeMillis().toInt(),
            authIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 3. Create slice using framework APIs
        val slice = createSlice(title, pendingIntent)

        // 4. Create presentation spec with size constraints
        val presentationSpec = InlinePresentationSpec.Builder(
            Size(300, 50),  // Minimum size (300px x 50px)
            Size(600, 100)  // Maximum size (600px x 100px)
        ).build()

        // 5. Return inline presentation
        return InlinePresentation(slice, presentationSpec, false)
    }

    @SuppressLint("RestrictedApi")
    @RequiresApi(Build.VERSION_CODES.R)
    private fun createSlice(title: String, pendingIntent: PendingIntent): Slice {
        val builder = InlineSuggestionUi.newContentBuilder(pendingIntent)
        builder.setTitle(title)

        return builder.build().slice
    }

    override fun onSaveRequest(
        request: SaveRequest,
        callback: SaveCallback
    ) {
        val context = request.fillContexts
        if (context.isEmpty()) {
            callback.onSuccess()
            return
        }

        val structure = context.last().structure
        val clientState = request.clientState

        var webDomain: String? = null
        var formUrl: String? = null
        val passwordId: String? = AutofillDataCache.getLastSelectedPasswordId()

        if (clientState != null) {
            webDomain = clientState.getString("webDomain")
            formUrl = clientState.getString("formUrl")
        }

        if (webDomain == null && BROWSER_PACKAGES.contains(structure.activityComponent?.packageName)) {
            val urlInfo = extractUrlFromBrowser(structure)
            webDomain = urlInfo.first
            formUrl = urlInfo.second
        }

        val parsedValues = parseSaveData(request)
        val username = parsedValues.first
        val password = parsedValues.second

        if (username != null && password != null) {
            val params = mutableMapOf<String, Any?>(
                "username" to username,
                "password" to password,
            )
            if (passwordId != null) {
                params["passwordId"] = passwordId
            }
            if (webDomain != null) {
                params["webDomain"] = webDomain
            }
            if (formUrl != null) {
                params["formUrl"] = formUrl
            }

            val packageName = structure.activityComponent?.packageName
            val appName = getApplicationName(packageName ?: "")
            if (packageName != null && !BROWSER_PACKAGES.contains(packageName)) {
                params["appPackage"] = packageName
                params["appName"] = appName
            }

            val authIntent = Intent(
                this@MpassAutofillService, AuthenticationActivity::class.java
            ).apply {
                putExtra(
                    AuthenticationActivity.EXTRA_USERNAME,
                    username
                )
                putExtra(
                    AuthenticationActivity.EXTRA_PASSWORD,
                    password
                )
                putExtra(
                    AuthenticationActivity.EXTRA_PACKAGE_NAME,
                    packageName
                )
                if (passwordId != null) {
                    putExtra(AuthenticationActivity.EXTRA_PASSWORD_ID, passwordId)
                }
            }

            val requestCode = System.currentTimeMillis().toInt()

            val pendingIntent = PendingIntent.getActivity(
                this@MpassAutofillService,
                requestCode,
                authIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            try {
                pendingIntent.send()
                callback.onSuccess()
            } catch (e: Exception) {
                callback.onSuccess()
            }
        } else {
            callback.onSuccess()
        }
    }

    private fun extractUrlFromBrowser(structure: AssistStructure): Pair<String?, String?> {
        var webDomain: String? = null
        var formUrl: String? = null

        for (i in 0 until structure.windowNodeCount) {
            val windowNode = structure.getWindowNodeAt(i)
            val rootViewNode = windowNode.rootViewNode

            if (rootViewNode.webDomain != null) {
                webDomain = rootViewNode.webDomain
                formUrl = extractFormActionUrl(rootViewNode)
                return Pair(webDomain, formUrl)
            }

            traverseNode(rootViewNode) { node ->
                if (node.webDomain != null && webDomain == null) {
                    webDomain = node.webDomain
                    formUrl = extractFormActionUrl(node)
                }

                if (webDomain == null) {
                    val text = node.text?.toString()
                    val idEntry = node.idEntry?.lowercase() ?: ""

                    if (text != null &&
                        (idEntry.contains("url") ||
                                idEntry.contains("search") ||
                                idEntry.contains("address"))
                    ) {

                        val possibleUrl = text.trim()
                        if (isLikelyUrl(possibleUrl)) {
                            webDomain = extractDomain(possibleUrl)
                        }
                    }
                }

                if (formUrl == null) {
                    formUrl = extractFormActionUrl(node)
                }

                webDomain != null && formUrl != null
            }

            if (webDomain != null) {
                break
            }
        }

        return Pair(webDomain, formUrl)
    }

    private fun extractFormActionUrl(node: AssistStructure.ViewNode): String? {
        val htmlInfo = node.htmlInfo ?: return null

        if (htmlInfo.tag.equals("form", ignoreCase = true)) {
            for (i in 0 until (htmlInfo.attributes?.size ?: 0)) {
                val attr = htmlInfo.attributes!![i]
                if (attr.first.equals("action", ignoreCase = true)) {
                    return attr.second
                }
            }
        }

        return null
    }

    private fun isLikelyUrl(text: String): Boolean {
        return text.contains(".") &&
                (text.startsWith("http://") ||
                        text.startsWith("https://") ||
                        !text.contains(" "))
    }

    private fun extractDomain(url: String): String {
        return try {
            val uri = Uri.parse(if (url.startsWith("http")) url else "https://$url")
            uri.host ?: url
        } catch (e: Exception) {
            url
        }
    }

    private fun createDatasetPresentation(title: String): RemoteViews {
        val presentation = RemoteViews(packageName, R.layout.autofill_item)
        presentation.setTextViewText(R.id.autofill_title, title)
        return presentation
    }

    private fun findAutofillableFields(structure: AssistStructure): Map<AutofillId, FieldType> {
        val fields = mutableMapOf<AutofillId, FieldType>()

        for (i in 0 until structure.windowNodeCount) {
            val windowNode = structure.getWindowNodeAt(i)
            val rootViewNode = windowNode.rootViewNode

            traverseNode(rootViewNode) { node ->
                val fieldType = determineFieldType(node)
                if (fieldType != FieldType.OTHER) {
                    node.autofillId?.let { id ->
                        fields[id] = fieldType
                    }
                }
                false
            }
        }

        return fields
    }

    private fun determineFieldType(node: AssistStructure.ViewNode): FieldType {
        // Check autofill hints first
        val autofillHints = node.autofillHints
        if (autofillHints != null) {
            for (hint in autofillHints) {
                when (hint) {
                    android.view.View.AUTOFILL_HINT_USERNAME,
                    android.view.View.AUTOFILL_HINT_EMAIL_ADDRESS -> return FieldType.USERNAME

                    android.view.View.AUTOFILL_HINT_PASSWORD -> return FieldType.PASSWORD
                }
            }
        }

        val inputType = node.inputType
        if (isPasswordInputType(inputType)) {
            return FieldType.PASSWORD
        }

        // Check HTML attributes for web forms
        val htmlAttributes = node.htmlInfo?.attributes
        if (htmlAttributes != null) {
            for (i in 0 until htmlAttributes.size) {
                val attribute = htmlAttributes[i]
                val name = attribute.first
                val value = attribute.second

                if (name.equals("type", ignoreCase = true)) {
                    when (value?.lowercase()) {
                        "password" -> return FieldType.PASSWORD
                        "email", "text" -> {
                            // Check if it's likely a username field
                            val idEntry = node.idEntry?.lowercase() ?: ""
                            val hint = node.hint?.toString()?.lowercase() ?: ""
                            if (containsUsernameTerm(idEntry) || containsUsernameTerm(hint)) {
                                return FieldType.USERNAME
                            }
                        }
                    }
                }
            }
        }

        // Check hint or field name
        val hint = node.hint?.lowercase() ?: ""
        val idEntry = node.idEntry?.lowercase() ?: ""
        if (containsUsernameTerm(hint) || containsUsernameTerm(idEntry)) {
            return FieldType.USERNAME
        }

        return FieldType.OTHER
    }

    // Helper to check for username-related terms
    private fun containsUsernameTerm(text: String): Boolean {
        val usernameTerms =
            listOf("user", "username", "email", "login", "account", "id", "identifier")
        return usernameTerms.any { term -> text.contains(term) }
    }

    private fun addSaveInfo(
        responseBuilder: FillResponse.Builder,
        fields: Map<AutofillId, FieldType>,
        webDomain: String?,
        formUrl: String?,
    ) {
        val usernameIds =
            fields.entries.filter { it.value == FieldType.USERNAME }.map { it.key }.toTypedArray()
        val passwordIds =
            fields.entries.filter { it.value == FieldType.PASSWORD }.map { it.key }.toTypedArray()

        if (usernameIds.isNotEmpty() && passwordIds.isNotEmpty()) {
            // Combine all IDs for the SaveInfo
            val allRequiredIds = usernameIds + passwordIds

            val saveInfoBuilder = SaveInfo.Builder(
                SaveInfo.SAVE_DATA_TYPE_USERNAME or SaveInfo.SAVE_DATA_TYPE_PASSWORD,
                allRequiredIds
            )

            // Add client state with website information if available
            val clientState = Bundle().apply {
                if (webDomain != null) putString("webDomain", webDomain)
                if (formUrl != null) putString("formUrl", formUrl)
                putParcelableArray("requiredIds", allRequiredIds)
            }
            responseBuilder.setClientState(clientState)

            responseBuilder.setSaveInfo(saveInfoBuilder.build())
        }
    }

    // Helper function to traverse the view hierarchy
    private fun traverseNode(
        node: AssistStructure.ViewNode,
        visitor: (AssistStructure.ViewNode) -> Boolean
    ) {
        // Process current node
        val stopTraversal = visitor(node)
        if (stopTraversal) {
            return
        }
        // Process children
        for (i in 0 until node.childCount) {
            traverseNode(node.getChildAt(i), visitor)
        }
    }

    // Check if input type indicates a password field
    private fun isPasswordInputType(inputType: Int): Boolean {
        val variation = inputType and android.text.InputType.TYPE_MASK_VARIATION
        val type = inputType and android.text.InputType.TYPE_MASK_CLASS

        return type == android.text.InputType.TYPE_CLASS_TEXT && (
                variation == android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                        variation == android.text.InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD ||
                        variation == android.text.InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD)
    }

    private fun parseSaveData(request: SaveRequest): Pair<String?, String?> {
        val fillContexts = request.fillContexts
        if (fillContexts.isEmpty()) return Pair(null, null)
        val structure = fillContexts.last().structure

        val clientState = request.clientState
        var requiredIds = emptyList<AutofillId>()

        if (clientState != null) {
            val parcelables = clientState.getParcelableArray("requiredIds")
            if (parcelables != null) {
                requiredIds = parcelables.filterIsInstance<AutofillId>()
            }
        }
        // If we couldn't get IDs from client state, try to find all autofillable fields
        if (requiredIds.isEmpty()) {
            val autofillableFields = findAutofillableFields(structure)
            requiredIds = autofillableFields.keys.toList()
        }

        val fields = mutableMapOf<FieldType, String>()
        for (autofillId in requiredIds) {
            traverseStructureForAutofillId(structure, autofillId) { node ->
                val fieldType = determineFieldType(node)
                val value = node.text?.toString()

                if (fieldType != FieldType.OTHER && value != null) {
                    fields[fieldType] = value
                }
                false
            }
        }

        val username = fields[FieldType.USERNAME]
        val password = fields[FieldType.PASSWORD]

        return Pair(username, password)
    }

    // Find a specific autofill ID in the structure
    private fun traverseStructureForAutofillId(
        structure: AssistStructure,
        targetId: AutofillId,
        visitor: (AssistStructure.ViewNode) -> Boolean
    ) {
        for (i in 0 until structure.windowNodeCount) {
            val windowNode = structure.getWindowNodeAt(i)
            val rootViewNode = windowNode.rootViewNode

            traverseNodeForAutofillId(rootViewNode, targetId, visitor)
        }
    }

    // Recursively traverse nodes looking for specific autofill ID
    private fun traverseNodeForAutofillId(
        node: AssistStructure.ViewNode,
        targetId: AutofillId,
        visitor: (AssistStructure.ViewNode) -> Boolean
    ): Boolean {
        // Check if this is the node we're looking for
        if (node.autofillId == targetId) {
            return visitor(node)
        }

        // Check children
        for (i in 0 until node.childCount) {
            if (traverseNodeForAutofillId(node.getChildAt(i), targetId, visitor)) {
                return true
            }
        }

        return false
    }

    private fun getApplicationName(packageName: String): String {
        return try {
            val packageManager = applicationContext.packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    override fun onDestroy() {
        flutterEngine.destroy()
        super.onDestroy()
    }
}