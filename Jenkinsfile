pipeline {
    agent any
    environment {
        FLUTTER_HOME = 'C:\\flutter_windows_3.41.2-stable\\flutter'
        ANDROID_HOME = 'C:\\Users\\ndiwa\\AppData\\Local\\Android\\Sdk'
        ANDROID_SDK_ROOT = 'C:\\Users\\ndiwa\\AppData\\Local\\Android\\Sdk'
        PATH = "${FLUTTER_HOME}\\bin;${ANDROID_HOME}\\platform-tools;${env.PATH}"
    }
    stages {
        stage('Fix Git Safe Directory') {
            steps {
                bat 'git config --global --add safe.directory C:/flutter_windows_3.41.2-stable/flutter'
                bat 'git config --global --add safe.directory *'
            }
        }
        stage('Clone Code') {
            steps {
                echo 'Cloning AgriNexa repository...'
                checkout scm
            }
        }
        stage('Flutter Doctor') {
            steps {
                bat 'flutter doctor'
            }
        }
        stage('Get Dependencies') {
            steps {
                bat 'flutter pub get'
            }
        }
        stage('Analyze Code') {
            steps {
                bat 'flutter analyze || exit 0'
            }
        }
        stage('Run Tests') {
            steps {
                bat 'flutter test'
            }
        }
        stage('Build APK') {
            steps {
                bat 'flutter build apk --release'
            }
        }
        stage('Archive APK') {
            steps {
                archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/app-release.apk',
                                 fingerprint: true,
                                 onlyIfSuccessful: true
            }
        }
    }
    post {
        success {
            echo 'AgriNexa Build Successful!'
            emailext(
                subject: "AgriNexa Build #${BUILD_NUMBER} - SUCCESS",
                body: """
                    <h2 style='color:green'>AgriNexa CI Build Successful!</h2>
                    <p><b>Build Number:</b> ${BUILD_NUMBER}</p>
                    <p><b>Branch:</b> ${GIT_BRANCH}</p>
                    <p><b>Duration:</b> ${currentBuild.durationString}</p>
                    <p>The APK has been built and archived successfully.</p>
                    <p><a href="${BUILD_URL}">View Build in Jenkins</a></p>
                """,
                mimeType: 'text/html',
                to: 'ndiwanetimothy04@gmail.com'
            )
        }
        failure {
            echo 'AgriNexa Build Failed! Check the logs.'
            emailext(
                subject: "AgriNexa Build #${BUILD_NUMBER} - FAILED",
                body: """
                    <h2 style='color:red'>AgriNexa CI Build Failed!</h2>
                    <p><b>Build Number:</b> ${BUILD_NUMBER}</p>
                    <p><b>Branch:</b> ${GIT_BRANCH}</p>
                    <p><b>Duration:</b> ${currentBuild.durationString}</p>
                    <p>Please check the logs and fix the issue.</p>
                    <p><a href="${BUILD_URL}console">View Console Output</a></p>
                """,
                mimeType: 'text/html',
                to: 'ndiwanetimothy04@gmail.com'
            )
        }
    }
}