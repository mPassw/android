package com.example.mpass

object AutofillDataCache {
    private var lastSelectedPasswordId: String? = null

    fun setLastSelectedPasswordId(id: String?) {
        lastSelectedPasswordId = id
    }

    fun getLastSelectedPasswordId(): String? {
        return lastSelectedPasswordId
    }

    // Clear this after handling a save request
    fun clearLastSelectedPasswordId() {
        lastSelectedPasswordId = null
    }
}