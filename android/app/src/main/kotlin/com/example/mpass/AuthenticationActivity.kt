package com.example.mpass

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Parcelable
import android.service.autofill.Dataset
import android.view.View
import android.view.WindowManager
import android.view.autofill.AutofillId
import android.view.autofill.AutofillManager
import android.view.autofill.AutofillValue
import androidx.core.os.bundleOf
import androidx.fragment.app.FragmentActivity
import io.flutter.FlutterInjector
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.loader.FlutterLoader

class AuthenticationActivity : FragmentActivity() {

    private val flutterEngineId = "authentication_engine"
    private lateinit var methodChannel: MethodChannel
    private lateinit var mainChannel: MethodChannel
    private val fragmentTag = "flutter_fragment"
    private lateinit var currentEngineId: String

    private var usernameAutofillId: Array<Parcelable>? = null
    private var passwordAutofillId: Array<Parcelable>? = null

    private var passwordId: String? = null
    private var username: String? = null
    private var password: String? = null
    private var packageName: String? = null

    companion object {
        private const val TAG = "AuthenticationActivity"
        const val EXTRA_USERNAME_AUTOFILL_ID = "extra_username_autofill_id"
        const val EXTRA_PASSWORD_AUTOFILL_ID = "extra_password_autofill_id"
        const val EXTRA_PASSWORD_ID = "extra_password_id"
        const val EXTRA_USERNAME = "extra_username"
        const val EXTRA_PASSWORD = "extra_password"
        const val EXTRA_PACKAGE_NAME = "extra_package_name"
        const val MAIN_CHANNEL_NAME = "com.example.mpass_autofill"
        const val DART_ENTRYPOINT = "autofillMain"
        const val AUTOFILL_METHOD_NAME = "showAutofill"
        const val AUTOSAVE_METHOD_NAME = "showAutosave"
    }

    private fun ensureFlutterEngineCreated() {
        val sessionEngineId = "$flutterEngineId-${System.currentTimeMillis()}"

        // Initialize FlutterLoader properly
        val flutterLoader = FlutterInjector.instance().flutterLoader()
        if (!flutterLoader.initialized()) {
            flutterLoader.startInitialization(applicationContext)
            flutterLoader.ensureInitializationComplete(applicationContext, null)
        }

        if (!FlutterEngineCache.getInstance().contains(sessionEngineId)) {
            val flutterEngine = FlutterEngine(applicationContext).apply {
                // Proper engine initialization
                dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(
                        flutterLoader.findAppBundlePath(),
                        DART_ENTRYPOINT
                    )
                )
            }
            FlutterEngineCache.getInstance().put(sessionEngineId, flutterEngine)
        }
        this.currentEngineId = sessionEngineId
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("MPASS", "Destroying")
        methodChannel.setMethodCallHandler(null)

        if (this::currentEngineId.isInitialized) {
            val engine = FlutterEngineCache.getInstance().get(currentEngineId)
            FlutterEngineCache.getInstance().remove(currentEngineId)
            engine?.destroy()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Add window configuration flags
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN

        setContentView(R.layout.activity_authentication)

        ensureFlutterEngineCreated()

        usernameAutofillId = intent.getParcelableArrayExtra(EXTRA_USERNAME_AUTOFILL_ID)
        passwordAutofillId = intent.getParcelableArrayExtra(EXTRA_PASSWORD_AUTOFILL_ID)

        passwordId = intent.getStringExtra(EXTRA_PASSWORD_ID)
        username = intent.getStringExtra(EXTRA_USERNAME)
        password = intent.getStringExtra(EXTRA_PASSWORD)
        packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME)

        val flutterEngine = FlutterEngineCache.getInstance().get(currentEngineId)!!
        methodChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, currentEngineId)
        mainChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAIN_CHANNEL_NAME)

        val existingFragment = supportFragmentManager.findFragmentByTag(fragmentTag)
        if (existingFragment == null) {
            val newFragment: FlutterFragment = FlutterFragment.withCachedEngine(currentEngineId)
                .shouldAttachEngineToActivity(true)
                .renderMode(RenderMode.surface)
                .transparencyMode(TransparencyMode.transparent)
                .build()

            supportFragmentManager.beginTransaction()
                .replace(R.id.flutter_container, newFragment, fragmentTag)
                .commit()
        }


        // Set up method channel to receive authentication result
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "authenticationSuccessful" -> {
                    val username = call.argument<String>("username") ?: ""
                    val password = call.argument<String>("password") ?: ""

                    fillCredentials(username, password)
                    result.success(true)
                    finish()
                }

                "authenticationFailed" -> {
                    result.success(true)
                    finish()
                }

                "autosaveSuccess" -> {
                    result.success(true)
                    finish()
                }

                "autosaveFailed" -> {
                    result.success(true)
                    finish()
                }

                else -> result.notImplemented()
            }
        }
        val isAutosave = usernameAutofillId == null && passwordAutofillId == null

        mainChannel.invokeMethod(
            if (isAutosave) AUTOSAVE_METHOD_NAME else AUTOFILL_METHOD_NAME, mapOf(
                "flutterEngineId" to currentEngineId,
            ),
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    if (theme.equals(R.style.LaunchTheme)) {
                        setTheme(R.style.NormalTheme)
                    }
                    setTheme(R.style.NormalTheme)
                    if (isAutosave) {
                        methodChannel.invokeMethod(
                            "initializeAutosave", mapOf(
                                "username" to username,
                                "password" to password,
                                "packageName" to packageName,
                            )
                        )
                    } else {
                        methodChannel.invokeMethod(
                            "initializeAutofill", mapOf(
                                "passwordId" to passwordId,
                            )
                        )
                    }
                }

                override fun error(code: String, message: String?, details: Any?) {

                }

                override fun notImplemented() {

                }
            }
        )
    }

    private fun fillCredentials(username: String, password: String) {
        // Create datasets for filling
        val dataset = Dataset.Builder().apply {
            usernameAutofillId?.forEach { autofillId ->
                setValue(autofillId as AutofillId, AutofillValue.forText(username))
            }
            passwordAutofillId?.forEach { autofillId ->
                setValue(autofillId as AutofillId, AutofillValue.forText(password))
            }
        }.build()

        // Set the result with the dataset
        setResult(Activity.RESULT_OK, Intent().apply {
            putExtras(bundleOf(AutofillManager.EXTRA_AUTHENTICATION_RESULT to dataset))
        })
    }
}