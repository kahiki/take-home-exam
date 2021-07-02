/*
    This is a CI/CD pipeline. Consisting of:
    github
    slack
    Google Cloud Builder
    Google Cloud Functions
    JFrog
    Jenkins Pipeline
    Kubernetes
    Lighthouse Inspector
    Ghost Inspector
    This pipeline is made up of the following:
        1. On code-release in git, via cloudbuild.yaml file, trigger Google Cloud Docker Build and notify to Slack
        2. Push images to JFrog
        3. Receive webhook from Google and automatically start Jenkins Job based on the Jenkins job token trigger
        4. Notify via Slack the various stages
        5. Deploy to Stage GCP-GKE 
        6. Optionally test with Lighthouse Inspector and Ghost Inspector SUITE_IDS
        7. Deploy to GKE UAT and then to PROD GKE, and test using Ghost Inspector SUITE_IDS
 */

/*
    Slack Channel - deploy
 */
def slackChannelMessage(color, message) {
  // Update slack channel as required
  def date = new Date()
  slackSend (channel: '#deploy', color: "${color}", message: "${message}")
}

/*
    Slack Channel - prod-deploy
 */
def slackChannelMessagePROD(color, message) {
  // Update slack channel as required
  def date = new Date()
  slackSend (channel: '#prod-deploy', color: "${color}", message: "${message}")
}

/*
    Slack Channel - log-deploy
 */
def slackChannelMessageLOG(color, message) {
  // Update slack channel as required
  def date = new Date()
  slackSend (channel: '#log-deploy', color: "${color}", message: "${message}")
}


/*
    Webhook Step - wait for POST curl to URL and then a PROMPT to confirm
 */
def webHookUrl(env_value) {

   script {
     def date = new Date()
     hook = registerWebhook()

     switch("${env_value}") {
       case 'PROD':
          slackChannelMessagePROD("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id - Please accept or decline release to ${env_value}: <${env.RUN_DISPLAY_URL}|Open>")
          // and accept or decline ${env_value} , Build #${env.BUILD_NUMBER} using TAG $git_tag_id for Image ${APP} and ${WEB} in PROD..
          def userInput = input(
          id: 'userInput', message: "${env.JOB_NAME} Are you sure you want to release to PROD - build ${env_value}, Build #${env.BUILD_NUMBER} using TAG $git_tag_id for Image ${APP} and ${WEB} ?", parameters: [
            [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Has the release followed the Production Deployment Checklist?', name: 'checklist'],
            [$class: 'StringParameterDefinition', defaultValue: '', description: 'Enter Email Address', name: 'emailAddress']
        ])
     
        echo ("User " +userInput['emailAddress'])
        echo ("Checklist accepted " +userInput['checklist'])
     
        slackChannelMessage("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: Released to Production by" +userInput['emailAddress'] + " .  Checklist accepted: " +userInput['checklist'])
       break
       default:
         slackChannelMessage("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: <${hook.getURL()}|Release to ${env_value}> <${env.RUN_DISPLAY_URL}|View Status>")
         // - ${env_value} -  Please accept or decline release to ${env_value}: <${env.RUN_DISPLAY_URL}|Open>   Click on this link to continue to progress to: ${env_value} , Build #${env.BUILD_NUMBER} for Image ${APP} and ${WEB} : 
         data = waitForWebhook hook
     }
   }


}

def getTAG(git_tag_id) {
    TAG = "$git_tag_id"

     echo "Release TAG: ${TAG}"

        FEATURE = sh (
                        script: """#!/bin/bash
                            echo $TAG | grep -i FEATURE
                                """,
                            returnStatus: true,
                    )

        if (FEATURE) {
                echo "FEATURE release is FALSE - Push image through all stages"
                FEATURE = false
                RUN_LIGHTHOUSE = true
                slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: <${env.RUN_DISPLAY_URL}|View Status>")
        }
        else
        {
                echo "FEATURE release is TRUE"
                FEATURE = true
                RUN_LIGHTHOUSE = true
                slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: FEATURE release for Staging only, <${env.RUN_DISPLAY_URL}|View Status>")
        }
}

/*
    Lighthouse Inspector function defining the tests run and the outputs
def runLighthouseInspector(url) {
    // Execute Lighthouse
    sh "lighthouse-ci ${url}"
    // Capture results to Jenkins
    def resultsHtml = sh(script: "cat /tmp/lighthouse_results.html", returnStdout: true).trim()
    def resultsJson = sh(script: "cat /tmp/lighthouse_results.json", returnStdout: true).trim()
    def resultsScreenshot = sh(script: "base64 /tmp/lighthouse_screenshot.png", returnStdout: true).trim()
    def scoresJson = sh(script: "cat /tmp/lighthouse_scores.json", returnStdout: true).trim()
    def (performanceScore, accessibilityScore, bestPracticesScore, seoScore, pwaScore) = sh(script: "cat /tmp/lighthouse_scores.out", returnStdout: true).trim().split("\r?\n")
    // Update global environment variables
    LIGHTHOUSE_RESULTS_HTML = "${resultsHtml}"
    LIGHTHOUSE_RESULTS_JSON = "${resultsJson}"
    LIGHTHOUSE_RESULTS_SCREENSHOT = "${resultsScreenshot}"
    LIGHTHOUSE_SCORES_JSON = "${scoresJson}"
    LIGHTHOUSE_SCORE_PERFORMANCE = "${performanceScore}"
    LIGHTHOUSE_SCORE_ACCESSIBILITY = "${accessibilityScore}"
    LIGHTHOUSE_SCORE_BEST_PRACTICES = "${bestPracticesScore}"
    LIGHTHOUSE_SCORE_SEO = "${seoScore}"
    LIGHTHOUSE_SCORE_PWA = "${pwaScore}"
    // Output scores
    echo "----- SCORES -----\nPerformance = ${LIGHTHOUSE_SCORE_PERFORMANCE}\nAccessibility = ${LIGHTHOUSE_SCORE_ACCESSIBILITY}\nBest Practices = ${LIGHTHOUSE_SCORE_BEST_PRACTICES}\nSEO = ${LIGHTHOUSE_SCORE_SEO}\nPWA = ${LIGHTHOUSE_SCORE_PWA}"
}
*/

/*
    Ghost Inspector Test
 */

def GhostInsTest (cluster_ENV, API_KEY, URL_TO_CHECK) {

 String[] SUITE_ID = []

 switch("${cluster_ENV}") {
   case 'prod':
       // Change according to Ghost Inspector PROD SUITE IDS
       SUITE_ID = []
      break
   case 'uat':
      // Change according to Ghost Inspector UAT SUITE IDS
      SUITE_ID = []
      break
   case 'stage':
      // Change according to Ghost Inspector STAGE SUITE IDS
      SUITE_ID = []
      break
  }

 echo "${cluster_ENV} list of IDs - ${SUITE_ID}"

 if (SUITE_ID.size() > 0) {
   for (int i = 0; i < SUITE_ID.size(); i++) {
     echo "Processing ${SUITE_ID[i]}"
     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} - ${cluster_ENV} - Running Ghost Inspector test using SUITE ID:- ${SUITE_ID[i]} , Build #${env.BUILD_NUMBER}, Image ${APP}:${TAG}..., <${env.RUN_DISPLAY_URL}|View Details>")
     sh """curl -s "https://api.ghostinspector.com/v1/suites/${SUITE_ID[i]}/execute/?apiKey=${API_KEY}&startUrl=https://${URL_TO_CHECK}" | jq -r . | grep -c '"code": "SUCCESS"' """
   }
 }
 else {
     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: ${cluster_ENV} - No Ghost Inspector test to run <${env.RUN_DISPLAY_URL}|View Status>")
     //  , Build #${env.BUILD_NUMBER}, Image ${APP}:${TAG}, Visit >
 }

}

/*
    Rolling Image update
 */
def rollingUpdate (cluster, namespace, deployment, cluster_ENV) {

  echo "JFrog Image ID = ${jfrog_URL}${REPO}-${APP}:$TAG"

  echo "Running Image ${jfrog_URL}${REPO}-${APP}:$TAG and ${jfrog_URL}${REPO}-${WEB}:$TAG on Kubernetes: ${cluster} for Env: ${cluster_ENV} on namespace: ${namespace} for Deployment ${deployment}"

  slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: Deploying ${jfrog_URL}${REPO}-${APP}:$TAG and ${jfrog_URL}${REPO}-${WEB}:$TAG on ${cluster} for Env: ${cluster_ENV} on namespace: ${namespace} for Deployment ${deployment}, <${env.RUN_DISPLAY_URL}|View Status>")

  switch("${cluster_ENV}") {

   case 'stage':
     withCredentials([
          [$class: 'FileBinding', credentialsId: "${STAGE_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY}", variable: 'STAGE_SAK']]) {

      // GKE gcloud STAGE

       sh "gcloud config set project ${STAGE_PROJECT_ID}"
       sh "gcloud config set compute/zone ${STAGE_ZONE}"

       sh "gcloud auth activate-service-account ${STAGE_GOOGLE_SERVICE_ACCOUNT} --key-file=${env.STAGE_SAK} --project=${STAGE_PROJECT_ID}"

      }
      break
   case 'uat':
      withCredentials([
        [$class: 'FileBinding', credentialsId: "${UAT_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY}", variable: 'UAT_SAK']]) {

      // GKE gcloud UAT

       sh "gcloud config set project ${UAT_PROJECT_ID}"
       sh "gcloud config set compute/zone ${UAT_ZONE}"

       sh "gcloud auth activate-service-account ${UAT_GOOGLE_SERVICE_ACCOUNT} --key-file=${env.UAT_SAK} --project=${UAT_PROJECT_ID}"

      }
      break
   case 'prod':
      withCredentials([
        [$class: 'FileBinding', credentialsId: "${PROD_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY}", variable: 'PROD_SAK']]) {

      // GKE gcloud PROD

       sh "gcloud config set project ${PROD_PROJECT_ID}"
       sh "gcloud config set compute/zone ${PROD_ZONE}"

       sh "gcloud auth activate-service-account ${PROD_GOOGLE_SERVICE_ACCOUNT} --key-file=${env.PROD_SAK} --project=${PROD_PROJECT_ID}"

      }
      break
    default:
        echo "No cluster varibale defined" 
      break 
 }

 sh "gcloud container clusters get-credentials ${cluster}"
 sh "kubectl set image -n ${namespace} deployments/${deployment} ${WEB}=${jfrog_URL}${REPO}-${WEB}:${TAG} --record"
 sh "kubectl set image -n ${namespace} deployments/${deployment} ${APP}=${jfrog_URL}${REPO}-${APP}:${TAG} --record"/*
    This is a CI/CD pipeline. Consisting of:
    github
    slack
    Google Cloud Builder
    Google Cloud Functions
    JFrog
    Jenkins Pipeline
    Kubernetes
    Lighthouse Inspector
    Ghost Inspector
    This pipeline is made up of the following:
        1. On code-release in git, via cloudbuild.yaml file, trigger Google Cloud Docker Build and notify to Slack
        2. Push images to JFrog
        3. Receive webhook from Google and automatically start Jenkins Job based on the Jenkins job token trigger
        4. Notify via Slack the various stages
        5. Deploy to Stage GCP-GKE 
        6. Optionally test with Lighthouse Inspector and Ghost Inspector SUITE_IDS
        7. Deploy to GKE UAT and then to PROD GKE, and test using Ghost Inspector SUITE_IDS
 */

/*
    Slack Channel - deploy
 */
def slackChannelMessage(color, message) {
  // Update slack channel as required
  def date = new Date()
  slackSend (channel: '#deploy', color: "${color}", message: "${message}")
}

/*
    Slack Channel - prod-deploy
 */
def slackChannelMessagePROD(color, message) {
  // Update slack channel as required
  def date = new Date()
  slackSend (channel: '#prod-deploy', color: "${color}", message: "${message}")
}

/*
    Slack Channel - log-deploy
 */
def slackChannelMessageLOG(color, message) {
  // Update slack channel as required
  def date = new Date()
  slackSend (channel: '#log-deploy', color: "${color}", message: "${message}")
}


/*
    Webhook Step - wait for POST curl to URL and then a PROMPT to confirm
 */
def webHookUrl(env_value) {

   script {
     def date = new Date()
     hook = registerWebhook()

     switch("${env_value}") {
       case 'PROD':
          slackChannelMessagePROD("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id - Please accept or decline release to ${env_value}: <${env.RUN_DISPLAY_URL}|Open>")
          // and accept or decline ${env_value} , Build #${env.BUILD_NUMBER} using TAG $git_tag_id for Image ${APP} and ${WEB} in PROD..
          def userInput = input(
          id: 'userInput', message: "${env.JOB_NAME} Are you sure you want to release to PROD - build ${env_value}, Build #${env.BUILD_NUMBER} using TAG $git_tag_id for Image ${APP} and ${WEB} ?", parameters: [
            [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Has the release followed the Production Deployment Checklist?', name: 'checklist'],
            [$class: 'StringParameterDefinition', defaultValue: '', description: 'Enter Email Address', name: 'emailAddress']
        ])
     
        echo ("User " +userInput['emailAddress'])
        echo ("Checklist accepted " +userInput['checklist'])
     
        slackChannelMessage("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: Released to Production by" +userInput['emailAddress'] + " .  Checklist accepted: " +userInput['checklist'])
       break
       default:
         slackChannelMessage("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: <${hook.getURL()}|Release to ${env_value}> <${env.RUN_DISPLAY_URL}|View Status>")
         // - ${env_value} -  Please accept or decline release to ${env_value}: <${env.RUN_DISPLAY_URL}|Open>   Click on this link to continue to progress to: ${env_value} , Build #${env.BUILD_NUMBER} for Image ${APP} and ${WEB} : 
         data = waitForWebhook hook
     }
   }


}

def getTAG(git_tag_id) {
    TAG = "$git_tag_id"

     echo "Release TAG: ${TAG}"

        FEATURE = sh (
                        script: """#!/bin/bash
                            echo $TAG | grep -i FEATURE
                                """,
                            returnStatus: true,
                    )

        if (FEATURE) {
                echo "FEATURE release is FALSE - Push image through all stages"
                FEATURE = false
                RUN_LIGHTHOUSE = true
                slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: <${env.RUN_DISPLAY_URL}|View Status>")
        }
        else
        {
                echo "FEATURE release is TRUE"
                FEATURE = true
                RUN_LIGHTHOUSE = true
                slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: FEATURE release for Staging only, <${env.RUN_DISPLAY_URL}|View Status>")
        }
}

/*
    Lighthouse Inspector function defining the tests run and the outputs
def runLighthouseInspector(url) {
    // Execute Lighthouse
    sh "lighthouse-ci ${url}"
    // Capture results to Jenkins
    def resultsHtml = sh(script: "cat /tmp/lighthouse_results.html", returnStdout: true).trim()
    def resultsJson = sh(script: "cat /tmp/lighthouse_results.json", returnStdout: true).trim()
    def resultsScreenshot = sh(script: "base64 /tmp/lighthouse_screenshot.png", returnStdout: true).trim()
    def scoresJson = sh(script: "cat /tmp/lighthouse_scores.json", returnStdout: true).trim()
    def (performanceScore, accessibilityScore, bestPracticesScore, seoScore, pwaScore) = sh(script: "cat /tmp/lighthouse_scores.out", returnStdout: true).trim().split("\r?\n")
    // Update global environment variables
    LIGHTHOUSE_RESULTS_HTML = "${resultsHtml}"
    LIGHTHOUSE_RESULTS_JSON = "${resultsJson}"
    LIGHTHOUSE_RESULTS_SCREENSHOT = "${resultsScreenshot}"
    LIGHTHOUSE_SCORES_JSON = "${scoresJson}"
    LIGHTHOUSE_SCORE_PERFORMANCE = "${performanceScore}"
    LIGHTHOUSE_SCORE_ACCESSIBILITY = "${accessibilityScore}"
    LIGHTHOUSE_SCORE_BEST_PRACTICES = "${bestPracticesScore}"
    LIGHTHOUSE_SCORE_SEO = "${seoScore}"
    LIGHTHOUSE_SCORE_PWA = "${pwaScore}"
    // Output scores
    echo "----- SCORES -----\nPerformance = ${LIGHTHOUSE_SCORE_PERFORMANCE}\nAccessibility = ${LIGHTHOUSE_SCORE_ACCESSIBILITY}\nBest Practices = ${LIGHTHOUSE_SCORE_BEST_PRACTICES}\nSEO = ${LIGHTHOUSE_SCORE_SEO}\nPWA = ${LIGHTHOUSE_SCORE_PWA}"
}
*/

/*
    Ghost Inspector Test
 */

def GhostInsTest (cluster_ENV, API_KEY, URL_TO_CHECK) {

 String[] SUITE_ID = []

 switch("${cluster_ENV}") {
   case 'prod':
       // Change according to Ghost Inspector PROD SUITE IDS
       SUITE_ID = []
      break
   case 'uat':
      // Change according to Ghost Inspector UAT SUITE IDS
      SUITE_ID = []
      break
   case 'stage':
      // Change according to Ghost Inspector STAGE SUITE IDS
      SUITE_ID = []
      break
  }

 echo "${cluster_ENV} list of IDs - ${SUITE_ID}"

 if (SUITE_ID.size() > 0) {
   for (int i = 0; i < SUITE_ID.size(); i++) {
     echo "Processing ${SUITE_ID[i]}"
     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} - ${cluster_ENV} - Running Ghost Inspector test using SUITE ID:- ${SUITE_ID[i]} , Build #${env.BUILD_NUMBER}, Image ${APP}:${TAG}..., <${env.RUN_DISPLAY_URL}|View Details>")
     sh """curl -s "https://api.ghostinspector.com/v1/suites/${SUITE_ID[i]}/execute/?apiKey=${API_KEY}&startUrl=https://${URL_TO_CHECK}" | jq -r . | grep -c '"code": "SUCCESS"' """
   }
 }
 else {
     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: ${cluster_ENV} - No Ghost Inspector test to run <${env.RUN_DISPLAY_URL}|View Status>")
     //  , Build #${env.BUILD_NUMBER}, Image ${APP}:${TAG}, Visit >
 }

}

/*
    Rolling Image update
 */
def rollingUpdate (cluster, namespace, deployment, cluster_ENV) {

  echo "JFrog Image ID = ${jfrog_URL}${REPO}-${APP}:$TAG"

  echo "Running Image ${jfrog_URL}${REPO}-${APP}:$TAG and ${jfrog_URL}${REPO}-${WEB}:$TAG on Kubernetes: ${cluster} for Env: ${cluster_ENV} on namespace: ${namespace} for Deployment ${deployment}"

  slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: Deploying ${jfrog_URL}${REPO}-${APP}:$TAG and ${jfrog_URL}${REPO}-${WEB}:$TAG on ${cluster} for Env: ${cluster_ENV} on namespace: ${namespace} for Deployment ${deployment}, <${env.RUN_DISPLAY_URL}|View Status>")

  switch("${cluster_ENV}") {

   case 'stage':
     withCredentials([
          [$class: 'FileBinding', credentialsId: "${STAGE_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY}", variable: 'STAGE_SAK']]) {

      // GKE gcloud STAGE

       sh "gcloud config set project ${STAGE_PROJECT_ID}"
       sh "gcloud config set compute/zone ${STAGE_ZONE}"

       sh "gcloud auth activate-service-account ${STAGE_GOOGLE_SERVICE_ACCOUNT} --key-file=${env.STAGE_SAK} --project=${STAGE_PROJECT_ID}"

      }
      break
   case 'uat':
      withCredentials([
        [$class: 'FileBinding', credentialsId: "${UAT_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY}", variable: 'UAT_SAK']]) {

      // GKE gcloud UAT

       sh "gcloud config set project ${UAT_PROJECT_ID}"
       sh "gcloud config set compute/zone ${UAT_ZONE}"

       sh "gcloud auth activate-service-account ${UAT_GOOGLE_SERVICE_ACCOUNT} --key-file=${env.UAT_SAK} --project=${UAT_PROJECT_ID}"

      }
      break
   case 'prod':
      withCredentials([
        [$class: 'FileBinding', credentialsId: "${PROD_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY}", variable: 'PROD_SAK']]) {

      // GKE gcloud PROD

       sh "gcloud config set project ${PROD_PROJECT_ID}"
       sh "gcloud config set compute/zone ${PROD_ZONE}"

       sh "gcloud auth activate-service-account ${PROD_GOOGLE_SERVICE_ACCOUNT} --key-file=${env.PROD_SAK} --project=${PROD_PROJECT_ID}"

      }
      break
    default:
        echo "No cluster varibale defined" 
      break 
 }

 sh "gcloud container clusters get-credentials ${cluster}"
 sh "kubectl set image -n ${namespace} deployments/${deployment} ${WEB}=${jfrog_URL}${REPO}-${WEB}:${TAG} --record"
 sh "kubectl rollout status -n ${namespace} deployments/${deployment}"
 sh "sleep 30"
 // LATEST_POD = sh (script: $/eval "kubectl get po -n ${namespace} -l app=${POD_LABEL} -o custom-columns=:metadata.name,:metadata.creationTimestamp | sort -k2 | cut -f 1 -d ' ' | tail -n 1"/$, returnStdout: true).trim()
 LATEST_POD = sh(script: "kubectl get po -n ${namespace} -l app=${POD_LABEL} -o custom-columns=:metadata.name,:metadata.creationTimestamp | sort -k2 | cut -f 1 -d ' ' | tail -n 1", returnStdout: true).trim()
}
/*
    Test with a simple curl and check we get 200 back
 */
 def curlTest (namespace, out, domain) {

     echo "Running tests in ${namespace}"

     script {
        if (out.equals('')) {
            out = 'http_code'
        }

        url = "https://${domain}"  // use https
       //  url = "http://${domain}" // use http
    }
}

/*
    Run a curl against a given url
 */

def curlRun (url, out) {

    echo "Running curl on ${url}"

    script {

        if (out.equals('')) {

            out = 'http_code'

        }

        echo "Getting ${out}"

            def result = sh (

                returnStdout: true,

                script: "curl --output /dev/null --silent --connect-timeout 5 --max-time 5 --retry 5 --retry-delay 5 --retry-max-time 30 --write-out \"%{${out}}\" ${url}"

        )

        echo "Result (${out}): ${result}"
    }
}


/*
    This is the main pipeline section with the stages of the CI/CD
 */

pipeline {

    agent none

    environment {

        // GCP-GKE STAGE
        STAGE_PROJECT_ID = ""
        STAGE_ZONE = "us-central1-a"
        STAGE_GOOGLE_SERVICE_ACCOUNT = "jenkins@development.iam.gserviceaccount.com"
        STAGE_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY = "jenkins_google_service_account"
        CLUSTER_STG = "staging"
        DEPLOYMENT_STG = "litecoin"
        STG_NAMESPACE = "stage"

        // GCP-GKE UAT - Update correctly when UAT GKE built
        UAT_PROJECT_ID = "take-home-exam-ag-uat-0005"
        UAT_ZONE = "us-east1-b"
        UAT_GOOGLE_SERVICE_ACCOUNT = "jenkins@take-home-exam-ag-uat-0005.iam.gserviceaccount.com"
        UAT_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY = "jenkins-service-account-take-home-exam-ag-uat"
        CLUSTER_UAT = "take-home-exam-ag-uat-cluster"
        DEPLOYMENT_UAT = "take-home-exam-ag-drupal"
        UAT_NAMESPACE = "uat"

        // GCP-GKE PROD - Update correctly when PROD GKE built
        PROD_PROJECT_ID = "take-home-exam-ag-prod-0005"
        PROD_ZONE = "us-east1"
        PROD_GOOGLE_SERVICE_ACCOUNT = "jenkins@take-home-exam-ag-prod-0005.iam.gserviceaccount.com"
        PROD_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY = "jenkins-service-account-take-home-exam-ag-prod"
        CLUSTER_PROD = "take-home-exam-ag-prod-cluster"
        DEPLOYMENT_PROD = "take-home-exam-ag-drupal"
        PROD_NAMESPACE = "prod-ag"

        APP = "drupal"
        WEB = "nginx"
        POD_LABEL = "take-home-exam-ag-drupal"

        // Curl Tests
        DOMAIN_STG = ""
        DOMAIN_UAT = ""
        DOMAIN_PROD = ""

        // Lighthouse Inspector
        // Core
        LIGHTHOUSE_ENABLED = false
        LIGHTHOUSE_SOURCE_Stage = "https://take-home-exam-ag-drupal.k8s.stage.take-home-exam.net/us/en"
        LIGHTHOUSE_SOURCE_PROD = "https://homeschool.harrowschoolonline.org"

        // Pass/Fail Score Thresholds
        LIGHTHOUSE_PERFORMANCE_THRESHOLD = 20
        LIGHTHOUSE_ACCESSIBILITY_THRESHOLD = 20
        LIGHTHOUSE_BEST_PRACTICES_THRESHOLD = 20
        LIGHTHOUSE_SEO_THRESHOLD = 20
        LIGHTHOUSE_PWA_THRESHOLD = 0

        // !! -- DO NOT EDIT -- !!
        LIGHTHOUSE_STAGE_SUCCESSFUL = false
        LIGHTHOUSE_RESULTS_HTML = ""
        LIGHTHOUSE_RESULTS_JSON = ""
        LIGHTHOUSE_RESULTS_SCREENSHOT = ""
        LIGHTHOUSE_SCORES_JSON = ""
        LIGHTHOUSE_SCORE_PERFORMANCE = 0
        LIGHTHOUSE_SCORE_ACCESSIBILITY = 0
        LIGHTHOUSE_SCORE_BEST_PRACTICES = 0
        LIGHTHOUSE_SCORE_SEO = 0
        LIGHTHOUSE_SCORE_PWA = 0

        // Ghost Inspector
        PROD_API_KEY= "cb49efd261b204a0e64fc1c1326fdf19f2fa5518"
        PROD_URL_TO_CHECK = "ag.take-home-exam.com"
        // Alter PROD_SUITE_IDS in GhostInsTest
        UAT_API_KEY= "cb49efd261b204a0e64fc1c1326fdf19f2fa5518"
        UAT_URL_TO_CHECK = "uat-take-home-exam-ag.take-home-exam.net"
        // Alter UAT_SUITE_IDS in GhostInsTest
        STAGE_API_KEY= "cb49efd261b204a0e64fc1c1326fdf19f2fa5518"
        STAGE_URL_TO_CHECK = "take-home-exam-ag-drupal.k8s.stage.take-home-exam.net"
        // Alter STAGE_SUITE_IDS in GhostInsTest


        // JFrog details
        SERVER_ID = "JF.jfrog01"
        jfrog_URL = "take-home-exam-docker.jfrog.io/"
        REPO = "take-home-exam-ag-drupal"

        TAG = ""

    }

// jenkins job token - Also update in cloudbuild.yaml
triggers {
    GenericTrigger(
     genericVariables: [
      [key: 'git_tag_id', value: '$.git_tag_id']
     ],
     causeString: 'Triggered on GIT Release TAG:- $git_tag_id',
     token: 'start-take-home-exam-ag-drupal-jenkinsfile',
     regexpFilterExpression: '',
     regexpFilterText: '',
     printContributedVariables: true,
     printPostContent: true
    )
  }

     options {
        skipDefaultCheckout()
    }

    stages {

         ////////// Step 1 //////////
         stage('Trigger received from Google WebHook') {

         agent {
          kubernetes {
            label 'jenkins-slaves-take-home-exam-ag-drupal'
            yamlFile 'jenkins/KubernetesPod.yaml'
          }
         }

            steps {
                 slackChannelMessage ("good", "Starting ${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: <${env.RUN_DISPLAY_URL}|View Status>")
                  script {
                    getTAG("$git_tag_id")
                  }
            }
            post {
                 failure {
                   echo "Failed to get release TAG"
                   slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER}: FAILED to get latest release TAG: <${env.RUN_DISPLAY_URL}|View Status>")
                 }
                 success {
                    echo "Successfully retreived release TAG: ${TAG}"
                    slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER}: SUCCESS using Release tag: $TAG <${env.RUN_DISPLAY_URL}|View Status>")
                }
            }

        }

        ////////// Step 2 ////////
        // Deploy to STAGE
        stage('Update STAGE Docker Image') {

          agent {
            kubernetes {
              label 'jenkins-slaves-take-home-exam-ag-drupal'
              yamlFile 'jenkins/KubernetesPod.yaml'
            }
          }

            // Deploy STAGE container selector

             steps {

              container('jenkins-kube-slave') {

                  script {
                     cluster = "${CLUSTER_STG}"
                     namespace = "${STG_NAMESPACE}"
                     deployment = "${DEPLOYMENT_STG}"
                     cluster_ENV = "stage"
                     echo "Perform rolling update of ${APP}:${TAG} to ${STG_NAMESPACE} namespace"
                     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using ${TAG}: ${APP}:${TAG} and ${WEB}:${TAG} updating in Staging. <${env.RUN_DISPLAY_URL}|View Status>")
                     milestone(1)
                     rollingUpdate (cluster, namespace, deployment, cluster_ENV)
                     milestone(2)
                 }
               }
             }
             post {
                  failure {
                    echo "Rolling update of image: ${APP}:${TAG} in ${STG_NAMESPACE} failed"
                    slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using ${TAG} FAILED to update in ${STG_NAMESPACE} on cluster: ${CLUSTER_STG}. <${env.RUN_DISPLAY_URL}|View Status>")
                  }
                  success {
                     echo "Successfully updated Image: ${APP}"
                     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using ${TAG} updated SUCCESSFULLY in ${STG_NAMESPACE} on ${CLUSTER_STG} in namespace ${namespace}. <${env.RUN_DISPLAY_URL}|View Status>")
                  }
             }

         }

       stage('STAGE Ghost Inspector Tests') {

          // Run Ghost Inspector Tests

            when {
                    expression { FEATURE == false }
                  }

                  agent {
                    kubernetes {
                      label 'jenkins-slaves-take-home-exam-ag-drupal'
                      yamlFile 'jenkins/KubernetesPod.yaml'
                    }
                  }

                    steps {
                            container('jenkins-chrome-slave') {

                            script {
                                     cluster_ENV = "stage"
                                     GhostInsTest (cluster_ENV, "${STAGE_API_KEY}", "${STAGE_URL_TO_CHECK}")
                            }

                          }
                    }
                    post {
                          failure {
                              slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: Ghost Inspector test FAILED <${env.RUN_DISPLAY_URL}|View Details>")
                          }
                          success {
                              slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: Ghost Inspector test PASSED/NOT RUN <${env.RUN_DISPLAY_URL}|View Details>")
                          }
                    }

          }

         ////////// Step 3 /////////
         // Wait for user manual approval before deploying to UAT - webhook
        stage('Deploy to UAT?') {

            when {
                     expression { FEATURE == false }
                 }

            steps {
                 milestone(3)
                 // Wait for POST to continue
                 webHookUrl('UAT')
                 milestone(4)

                 script {
                     DEPLOY_UAT = true
                 }
             }
        }


        stage('Update UAT Docker Image') {

             when {
                     expression { FEATURE == false }
             }

             agent {
               kubernetes {
                 label 'jenkins-slaves-take-home-exam-ag-drupal'
                 yamlFile 'jenkins/KubernetesPod.yaml'
               }
             }

            // Deploy UAT agent selector - KUBE

             steps {
              container('jenkins-kube-slave') {
                  script {
                     cluster = "${CLUSTER_UAT}"
                     namespace = "${UAT_NAMESPACE}"
                     deployment = "${DEPLOYMENT_UAT}"
                     cluster_ENV = "uat"
                     echo "Perform rolling update of ${APP}:${TAG} and ${WEB}:${TAG} to ${UAT_NAMESPACE} namespace"
                     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG ${TAG}: update in UAT has started <${env.RUN_DISPLAY_URL}|View Details>")
                     rollingUpdate (cluster, namespace, deployment, cluster_ENV)
                 }
               }
             }
             post {
                  failure {
                    echo "Rolling update of image: ${APP}:${TAG} in ${UAT_NAMESPACE} failed"
                    slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} FAILED to update, <${env.RUN_DISPLAY_URL}|View Details>")
                  }
                  success {
                     echo "Successfully updated Image: ${APP}"
                     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} updated SUCCESSFULLY to UAT, <${env.RUN_DISPLAY_URL}|View Details>")
                  }
             }

         }

         stage('UAT Ghost Inspector Tests') {

         // Run Ghost Inspector Tests

           when {
                   expression { FEATURE == false }
                 }

                 agent {
                   kubernetes {
                     label 'jenkins-slaves-take-home-exam-ag-drupal'
                     yamlFile 'jenkins/KubernetesPod.yaml'
                   }
                 }

                   steps {
                           container('jenkins-chrome-slave') {

                           script {
                                    cluster_ENV = "uat"
                                    GhostInsTest (cluster_ENV, "${UAT_API_KEY}", "${UAT_URL_TO_CHECK}")
                           }

                         }
                   }
                   post {
                         failure {
                             slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: Ghost Inspector test FAILED <${env.RUN_DISPLAY_URL}|View Details>")
                         }
                         success {
                             slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: Ghost Inspector test PASSED/NOT RUN <${env.RUN_DISPLAY_URL}|View Details>")
                         }
                   }

         }

         ////////// Step 4 //////////
         // Wait for user manual approval before deploying to PROD
         stage('Deploy to PROD?') {

           when {
                   expression { FEATURE == false }
                }

             steps {
                     milestone(5)
                     // Wait for POST to continue
                     webHookUrl('PROD')
                     milestone(6)

                     script {
                             DEPLOY_PROD = true
                            }
                   }
           }

           stage('Update PROD Docker Image') {

               // Deploy PROD container selector

                 when {
                         expression {  FEATURE == false }
                       }

                   agent {
                       kubernetes {
                       label 'jenkins-slaves-take-home-exam-ag-drupal'
                       yamlFile 'jenkins/KubernetesPod.yaml'
                         }
                   }

                   steps {

                           container('jenkins-kube-slave') {

                               script {
                                        cluster = "${CLUSTER_PROD}"
                                        namespace = "${PROD_NAMESPACE}"
                                        deployment = "${DEPLOYMENT_PROD}"
                                        cluster_ENV = "prod"
                                        echo "Perform rolling update of ${APP}:${TAG} and ${WEB}:${TAG} to ${PROD_NAMESPACE} namespace"
                                        slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: rolling update in PROD has started on cluster: ${cluster} in namespace ${namespace} > <${env.RUN_DISPLAY_URL}|View Details>")
                                        rollingUpdate (cluster, namespace, deployment, cluster_ENV)
                                      }
                             }
                   }
                   post {
                          failure {
                                    echo "Rolling update of image: ${APP}:${TAG} in ${PROD_NAMESPACE} failed"
                                    slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: FAILED to update in ${PROD_NAMESPACE} on cluster: ${CLUSTER_PROD}, <${env.RUN_DISPLAY_URL}|View Details>")
                                  }
                          success {
                                    echo "Successfully updated Image: ${APP}"
                                    slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: updated SUCCESSFULLY in ${PROD_NAMESPACE} on ${CLUSTER_PROD} in namespace ${namespace}, <${env.RUN_DISPLAY_URL}|View Details>")
                                  }
                         }

           }

         stage('PROD Ghost Inspector Tests') {

           // Run Ghost Inspector Tests

             when {
                     expression { FEATURE == false }
                   }

                   agent {
                       kubernetes {
                       label 'jenkins-slaves-take-home-exam-ag-drupal'
                       yamlFile 'jenkins/KubernetesPod.yaml'
                         }
                   }

                     steps {
                             container('jenkins-chrome-slave') {

                             script {
                                      cluster_ENV = "prod"
                                      GhostInsTest (cluster_ENV, "${PROD_API_KEY}", "${PROD_URL_TO_CHECK}")
                             }

                           }
                     }
                     post {
                           failure {
                               slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: - ${cluster_ENV} - Ghost Inspector test FAILED <${env.RUN_DISPLAY_URL}|View Details>")
                           }
                           success {
                               slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: - ${cluster_ENV} - Ghost Inspector test PASSED/NOT RUN <${env.RUN_DISPLAY_URL}|View Details>")
                           }
                     }

           }


    }
    post {
            failure {
              echo "Pipeline currentResult: ${currentBuild.currentResult}"
              slackChannelMessage ("danger", "** Pipeline ${currentBuild.currentResult} for ${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: ${currentBuild.currentResult} <${env.RUN_DISPLAY_URL}|View Details>")
            }
            success {
              echo "Pipeline currentResult: ${currentBuild.currentResult}"
              slackChannelMessage ("good", "** Pipeline completed for ${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: ${currentBuild.currentResult} <${env.RUN_DISPLAY_URL}|View Details>")
           }
   }

}

 sh "kubectl set image -n ${namespace} cronjob/take-home-exam-ag-drupal-drush-cron take-home-exam-ag-drupal-drush-cron=${jfrog_URL}${REPO}-${APP}:${TAG} --record"
 sh "kubectl rollout status -n ${namespace} deployments/${deployment}"
 sh "sleep 30"
 // LATEST_POD = sh (script: $/eval "kubectl get po -n ${namespace} -l app=${POD_LABEL} -o custom-columns=:metadata.name,:metadata.creationTimestamp | sort -k2 | cut -f 1 -d ' ' | tail -n 1"/$, returnStdout: true).trim()
 LATEST_POD = sh(script: "kubectl get po -n ${namespace} -l app=${POD_LABEL} -o custom-columns=:metadata.name,:metadata.creationTimestamp | sort -k2 | cut -f 1 -d ' ' | tail -n 1", returnStdout: true).trim()
 sh "kubectl exec -n ${namespace} ${LATEST_POD} deploy.sh"
 sh "kubectl exec -n ${namespace} ${LATEST_POD} killall php-fpm &"
}
/*
    Test with a simple curl and check we get 200 back
 */
 def curlTest (namespace, out, domain) {

     echo "Running tests in ${namespace}"

     script {
        if (out.equals('')) {
            out = 'http_code'
        }

        url = "https://${domain}"  // use https
       //  url = "http://${domain}" // use http
    }
}

/*
    Run a curl against a given url
 */

def curlRun (url, out) {

    echo "Running curl on ${url}"

    script {

        if (out.equals('')) {

            out = 'http_code'

        }

        echo "Getting ${out}"

            def result = sh (

                returnStdout: true,

                script: "curl --output /dev/null --silent --connect-timeout 5 --max-time 5 --retry 5 --retry-delay 5 --retry-max-time 30 --write-out \"%{${out}}\" ${url}"

        )

        echo "Result (${out}): ${result}"
    }
}


/*
    This is the main pipeline section with the stages of the CI/CD
 */

pipeline {

    agent none

    environment {

        // GCP-GKE STAGE
        STAGE_PROJECT_ID = ""
        STAGE_ZONE = "us-central1-a"
        STAGE_GOOGLE_SERVICE_ACCOUNT = "jenkins@development.iam.gserviceaccount.com"
        STAGE_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY = "jenkins_google_service_account"
        CLUSTER_STG = "staging"
        DEPLOYMENT_STG = "litecoin"
        STG_NAMESPACE = "stage"

        // GCP-GKE UAT - Update correctly when UAT GKE built
        UAT_PROJECT_ID = "take-home-exam-ag-uat-0005"
        UAT_ZONE = "us-east1-b"
        UAT_GOOGLE_SERVICE_ACCOUNT = "jenkins@take-home-exam-ag-uat-0005.iam.gserviceaccount.com"
        UAT_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY = "jenkins-service-account-take-home-exam-ag-uat"
        CLUSTER_UAT = "take-home-exam-ag-uat-cluster"
        DEPLOYMENT_UAT = "take-home-exam-ag-drupal"
        UAT_NAMESPACE = "uat"

        // GCP-GKE PROD - Update correctly when PROD GKE built
        PROD_PROJECT_ID = "take-home-exam-ag-prod-0005"
        PROD_ZONE = "us-east1"
        PROD_GOOGLE_SERVICE_ACCOUNT = "jenkins@take-home-exam-ag-prod-0005.iam.gserviceaccount.com"
        PROD_JENKINS_GOOGLE_SERVICE_ACCOUNT_KEY = "jenkins-service-account-take-home-exam-ag-prod"
        CLUSTER_PROD = "take-home-exam-ag-prod-cluster"
        DEPLOYMENT_PROD = "take-home-exam-ag-drupal"
        PROD_NAMESPACE = "prod-ag"

        APP = "drupal"
        WEB = "nginx"
        POD_LABEL = "take-home-exam-ag-drupal"

        // Curl Tests
        DOMAIN_STG = ""
        DOMAIN_UAT = ""
        DOMAIN_PROD = ""

        // Lighthouse Inspector
        // Core
        LIGHTHOUSE_ENABLED = false
        LIGHTHOUSE_SOURCE_Stage = "https://take-home-exam-ag-drupal.k8s.stage.take-home-exam.net/us/en"
        LIGHTHOUSE_SOURCE_PROD = "https://homeschool.harrowschoolonline.org"

        // Pass/Fail Score Thresholds
        LIGHTHOUSE_PERFORMANCE_THRESHOLD = 20
        LIGHTHOUSE_ACCESSIBILITY_THRESHOLD = 20
        LIGHTHOUSE_BEST_PRACTICES_THRESHOLD = 20
        LIGHTHOUSE_SEO_THRESHOLD = 20
        LIGHTHOUSE_PWA_THRESHOLD = 0

        // !! -- DO NOT EDIT -- !!
        LIGHTHOUSE_STAGE_SUCCESSFUL = false
        LIGHTHOUSE_RESULTS_HTML = ""
        LIGHTHOUSE_RESULTS_JSON = ""
        LIGHTHOUSE_RESULTS_SCREENSHOT = ""
        LIGHTHOUSE_SCORES_JSON = ""
        LIGHTHOUSE_SCORE_PERFORMANCE = 0
        LIGHTHOUSE_SCORE_ACCESSIBILITY = 0
        LIGHTHOUSE_SCORE_BEST_PRACTICES = 0
        LIGHTHOUSE_SCORE_SEO = 0
        LIGHTHOUSE_SCORE_PWA = 0

        // Ghost Inspector
        PROD_API_KEY= "cb49efd261b204a0e64fc1c1326fdf19f2fa5518"
        PROD_URL_TO_CHECK = "ag.take-home-exam.com"
        // Alter PROD_SUITE_IDS in GhostInsTest
        UAT_API_KEY= "cb49efd261b204a0e64fc1c1326fdf19f2fa5518"
        UAT_URL_TO_CHECK = "uat-take-home-exam-ag.take-home-exam.net"
        // Alter UAT_SUITE_IDS in GhostInsTest
        STAGE_API_KEY= "cb49efd261b204a0e64fc1c1326fdf19f2fa5518"
        STAGE_URL_TO_CHECK = "take-home-exam-ag-drupal.k8s.stage.take-home-exam.net"
        // Alter STAGE_SUITE_IDS in GhostInsTest


        // JFrog details
        SERVER_ID = "JF.jfrog01"
        jfrog_URL = "take-home-exam-docker.jfrog.io/"
        REPO = "take-home-exam-ag-drupal"

        TAG = ""

    }

// jenkins job token - Also update in cloudbuild.yaml
triggers {
    GenericTrigger(
     genericVariables: [
      [key: 'git_tag_id', value: '$.git_tag_id']
     ],
     causeString: 'Triggered on GIT Release TAG:- $git_tag_id',
     token: 'start-take-home-exam-ag-drupal-jenkinsfile',
     regexpFilterExpression: '',
     regexpFilterText: '',
     printContributedVariables: true,
     printPostContent: true
    )
  }

     options {
        skipDefaultCheckout()
    }

    stages {

         ////////// Step 1 //////////
         stage('Trigger received from Google WebHook') {

         agent {
          kubernetes {
            label 'jenkins-slaves-take-home-exam-ag-drupal'
            yamlFile 'jenkins/KubernetesPod.yaml'
          }
         }

            steps {
                 slackChannelMessage ("good", "Starting ${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: <${env.RUN_DISPLAY_URL}|View Status>")
                  script {
                    getTAG("$git_tag_id")
                  }
            }
            post {
                 failure {
                   echo "Failed to get release TAG"
                   slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER}: FAILED to get latest release TAG: <${env.RUN_DISPLAY_URL}|View Status>")
                 }
                 success {
                    echo "Successfully retreived release TAG: ${TAG}"
                    slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER}: SUCCESS using Release tag: $TAG <${env.RUN_DISPLAY_URL}|View Status>")
                }
            }

        }

        ////////// Step 2 ////////
        // Deploy to STAGE
        stage('Update STAGE Docker Image') {

          agent {
            kubernetes {
              label 'jenkins-slaves-take-home-exam-ag-drupal'
              yamlFile 'jenkins/KubernetesPod.yaml'
            }
          }

            // Deploy STAGE container selector

             steps {

              container('jenkins-kube-slave') {

                  script {
                     cluster = "${CLUSTER_STG}"
                     namespace = "${STG_NAMESPACE}"
                     deployment = "${DEPLOYMENT_STG}"
                     cluster_ENV = "stage"
                     echo "Perform rolling update of ${APP}:${TAG} to ${STG_NAMESPACE} namespace"
                     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using ${TAG}: ${APP}:${TAG} and ${WEB}:${TAG} updating in Staging. <${env.RUN_DISPLAY_URL}|View Status>")
                     milestone(1)
                     rollingUpdate (cluster, namespace, deployment, cluster_ENV)
                     milestone(2)
                 }
               }
             }
             post {
                  failure {
                    echo "Rolling update of image: ${APP}:${TAG} in ${STG_NAMESPACE} failed"
                    slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using ${TAG} FAILED to update in ${STG_NAMESPACE} on cluster: ${CLUSTER_STG}. <${env.RUN_DISPLAY_URL}|View Status>")
                  }
                  success {
                     echo "Successfully updated Image: ${APP}"
                     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using ${TAG} updated SUCCESSFULLY in ${STG_NAMESPACE} on ${CLUSTER_STG} in namespace ${namespace}. <${env.RUN_DISPLAY_URL}|View Status>")
                  }
             }

         }

       stage('STAGE Ghost Inspector Tests') {

          // Run Ghost Inspector Tests

            when {
                    expression { FEATURE == false }
                  }

                  agent {
                    kubernetes {
                      label 'jenkins-slaves-take-home-exam-ag-drupal'
                      yamlFile 'jenkins/KubernetesPod.yaml'
                    }
                  }

                    steps {
                            container('jenkins-chrome-slave') {

                            script {
                                     cluster_ENV = "stage"
                                     GhostInsTest (cluster_ENV, "${STAGE_API_KEY}", "${STAGE_URL_TO_CHECK}")
                            }

                          }
                    }
                    post {
                          failure {
                              slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: Ghost Inspector test FAILED <${env.RUN_DISPLAY_URL}|View Details>")
                          }
                          success {
                              slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG $git_tag_id: Ghost Inspector test PASSED/NOT RUN <${env.RUN_DISPLAY_URL}|View Details>")
                          }
                    }

          }

         ////////// Step 3 /////////
         // Wait for user manual approval before deploying to UAT - webhook
        stage('Deploy to UAT?') {

            when {
                     expression { FEATURE == false }
                 }

            steps {
                 milestone(3)
                 // Wait for POST to continue
                 webHookUrl('UAT')
                 milestone(4)

                 script {
                     DEPLOY_UAT = true
                 }
             }
        }


        stage('Update UAT Docker Image') {

             when {
                     expression { FEATURE == false }
             }

             agent {
               kubernetes {
                 label 'jenkins-slaves-take-home-exam-ag-drupal'
                 yamlFile 'jenkins/KubernetesPod.yaml'
               }
             }

            // Deploy UAT agent selector - KUBE

             steps {
              container('jenkins-kube-slave') {
                  script {
                     cluster = "${CLUSTER_UAT}"
                     namespace = "${UAT_NAMESPACE}"
                     deployment = "${DEPLOYMENT_UAT}"
                     cluster_ENV = "uat"
                     echo "Perform rolling update of ${APP}:${TAG} and ${WEB}:${TAG} to ${UAT_NAMESPACE} namespace"
                     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using TAG ${TAG}: update in UAT has started <${env.RUN_DISPLAY_URL}|View Details>")
                     rollingUpdate (cluster, namespace, deployment, cluster_ENV)
                 }
               }
             }
             post {
                  failure {
                    echo "Rolling update of image: ${APP}:${TAG} in ${UAT_NAMESPACE} failed"
                    slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} FAILED to update, <${env.RUN_DISPLAY_URL}|View Details>")
                  }
                  success {
                     echo "Successfully updated Image: ${APP}"
                     slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} updated SUCCESSFULLY to UAT, <${env.RUN_DISPLAY_URL}|View Details>")
                  }
             }

         }

         stage('UAT Ghost Inspector Tests') {

         // Run Ghost Inspector Tests

           when {
                   expression { FEATURE == false }
                 }

                 agent {
                   kubernetes {
                     label 'jenkins-slaves-take-home-exam-ag-drupal'
                     yamlFile 'jenkins/KubernetesPod.yaml'
                   }
                 }

                   steps {
                           container('jenkins-chrome-slave') {

                           script {
                                    cluster_ENV = "uat"
                                    GhostInsTest (cluster_ENV, "${UAT_API_KEY}", "${UAT_URL_TO_CHECK}")
                           }

                         }
                   }
                   post {
                         failure {
                             slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: Ghost Inspector test FAILED <${env.RUN_DISPLAY_URL}|View Details>")
                         }
                         success {
                             slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: Ghost Inspector test PASSED/NOT RUN <${env.RUN_DISPLAY_URL}|View Details>")
                         }
                   }

         }

         ////////// Step 4 //////////
         // Wait for user manual approval before deploying to PROD
         stage('Deploy to PROD?') {

           when {
                   expression { FEATURE == false }
                }

             steps {
                     milestone(5)
                     // Wait for POST to continue
                     webHookUrl('PROD')
                     milestone(6)

                     script {
                             DEPLOY_PROD = true
                            }
                   }
           }

           stage('Update PROD Docker Image') {

               // Deploy PROD container selector

                 when {
                         expression {  FEATURE == false }
                       }

                   agent {
                       kubernetes {
                       label 'jenkins-slaves-take-home-exam-ag-drupal'
                       yamlFile 'jenkins/KubernetesPod.yaml'
                         }
                   }

                   steps {

                           container('jenkins-kube-slave') {

                               script {
                                        cluster = "${CLUSTER_PROD}"
                                        namespace = "${PROD_NAMESPACE}"
                                        deployment = "${DEPLOYMENT_PROD}"
                                        cluster_ENV = "prod"
                                        echo "Perform rolling update of ${APP}:${TAG} and ${WEB}:${TAG} to ${PROD_NAMESPACE} namespace"
                                        slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: rolling update in PROD has started on cluster: ${cluster} in namespace ${namespace} > <${env.RUN_DISPLAY_URL}|View Details>")
                                        rollingUpdate (cluster, namespace, deployment, cluster_ENV)
                                      }
                             }
                   }
                   post {
                          failure {
                                    echo "Rolling update of image: ${APP}:${TAG} in ${PROD_NAMESPACE} failed"
                                    slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: FAILED to update in ${PROD_NAMESPACE} on cluster: ${CLUSTER_PROD}, <${env.RUN_DISPLAY_URL}|View Details>")
                                  }
                          success {
                                    echo "Successfully updated Image: ${APP}"
                                    slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: updated SUCCESSFULLY in ${PROD_NAMESPACE} on ${CLUSTER_PROD} in namespace ${namespace}, <${env.RUN_DISPLAY_URL}|View Details>")
                                  }
                         }

           }

         stage('PROD Ghost Inspector Tests') {

           // Run Ghost Inspector Tests

             when {
                     expression { FEATURE == false }
                   }

                   agent {
                       kubernetes {
                       label 'jenkins-slaves-take-home-exam-ag-drupal'
                       yamlFile 'jenkins/KubernetesPod.yaml'
                         }
                   }

                     steps {
                             container('jenkins-chrome-slave') {

                             script {
                                      cluster_ENV = "prod"
                                      GhostInsTest (cluster_ENV, "${PROD_API_KEY}", "${PROD_URL_TO_CHECK}")
                             }

                           }
                     }
                     post {
                           failure {
                               slackChannelMessageLOG("danger", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: - ${cluster_ENV} - Ghost Inspector test FAILED <${env.RUN_DISPLAY_URL}|View Details>")
                           }
                           success {
                               slackChannelMessageLOG("good", "${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: - ${cluster_ENV} - Ghost Inspector test PASSED/NOT RUN <${env.RUN_DISPLAY_URL}|View Details>")
                           }
                     }

           }


    }
    post {
            failure {
              echo "Pipeline currentResult: ${currentBuild.currentResult}"
              slackChannelMessage ("danger", "** Pipeline ${currentBuild.currentResult} for ${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: ${currentBuild.currentResult} <${env.RUN_DISPLAY_URL}|View Details>")
            }
            success {
              echo "Pipeline currentResult: ${currentBuild.currentResult}"
              slackChannelMessage ("good", "** Pipeline completed for ${env.JOB_NAME} Build #${env.BUILD_NUMBER} using $git_tag_id: ${currentBuild.currentResult} <${env.RUN_DISPLAY_URL}|View Details>")
           }
   }

}
