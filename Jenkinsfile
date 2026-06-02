post {
    success {
        echo '✅ AgriNexa Build Successful!'
        emailext(
            subject: "✅ AgriNexa Build #${BUILD_NUMBER} - SUCCESS",
            body: """
                <h2>✅ AgriNexa CI Build Successful!</h2>
                <p><b>Build Number:</b> ${BUILD_NUMBER}</p>
                <p><b>Branch:</b> ${GIT_BRANCH}</p>
                <p><b>Duration:</b> ${currentBuild.durationString}</p>
                <p>The APK has been built and archived successfully.</p>
                <p><a href="${BUILD_URL}">View Build in Jenkins</a></p>
            """,
            mimeType: 'text/html',
            to: 'YOUR_GMAIL_HERE'
        )
    }
    failure {
        echo '❌ AgriNexa Build Failed! Check the logs.'
        emailext(
            subject: "❌ AgriNexa Build #${BUILD_NUMBER} - FAILED",
            body: """
                <h2>❌ AgriNexa CI Build Failed!</h2>
                <p><b>Build Number:</b> ${BUILD_NUMBER}</p>
                <p><b>Branch:</b> ${GIT_BRANCH}</p>
                <p><b>Duration:</b> ${currentBuild.durationString}</p>
                <p>Please check the logs and fix the issue.</p>
                <p><a href="${BUILD_URL}console">View Console Output</a></p>
            """,
            mimeType: 'text/html',
            to: 'YOUR_GMAIL_HERE'
        )
    }
}