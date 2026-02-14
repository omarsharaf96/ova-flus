package com.ovaflus.app.data.remote

import com.amplifyframework.auth.cognito.AWSCognitoAuthSession
import com.amplifyframework.auth.options.AuthFetchSessionOptions
import com.amplifyframework.core.Amplify
import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

class AuthInterceptor @Inject constructor() : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val token = runBlocking { getAccessToken() }
        val request = if (token != null) {
            chain.request().newBuilder()
                .addHeader("Authorization", "Bearer $token")
                .build()
        } else {
            chain.request()
        }
        return chain.proceed(request)
    }

    private suspend fun getAccessToken(): String? {
        return try {
            suspendCoroutine { continuation ->
                Amplify.Auth.fetchAuthSession(
                    { session ->
                        val cognitoSession = session as? AWSCognitoAuthSession
                        val token = cognitoSession?.userPoolTokensResult?.value?.accessToken
                        continuation.resume(token)
                    },
                    { error ->
                        continuation.resumeWithException(error)
                    },
                )
            }
        } catch (e: Exception) {
            null
        }
    }
}
