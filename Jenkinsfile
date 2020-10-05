#!groovy
pipeline {
  agent {
    node {
      label 'sgune-worker'
    }
  } //agent
  
  options {
    disableConcurrentBuilds()
    ansiColor('xterm')
  } //option

  environment {
    def BRANCH_NAME = "${BRANCH_NAME ?: 'default'}"
    def info = repoInfo()
  }

  stages {
    stage('Validate Changelog') {
      steps {
        script {
          if (!fileExists('CHANGELOG.md')) {
            error("CHANGELOG does not exist")
          }
          env.CHANGELOG_VERSION = sh (
            script: 'grep -m 1 "^[0-9]*\\.[0-9]*\\.[0-9]*$" CHANGELOG.md',
            returnStdout: true
          ).trim()
          println "CHANGELOG VERSION"
          println "${CHANGELOG_VERSION}"

          if (BRANCH_NAME != 'master') {
            println "Checking if CHANGELOG version is different than master"
            env.CHANGELOG_DIFF = sh (
              script: "git diff origin/master origin/${env.BRANCH_NAME} CHANGELOG.md | grep ${CHANGELOG_VERSION}",
              returnStdout: true
            ).trim()
            if (!CHANGELOG_DIFF) {
              error("CHANGELOG version not updated")
            }
          }
        }
      }
    } // stage('Validate Changelog')
    stage('Docker Build') {
      steps {
        script {
          echo "Building Docker Image"
          sh "docker build --pull -t shreyasgune/moxi-cbase:${CHANGELOG_VERSION}-${env.BUILD_NUMBER} -f Dockerfile . "
        }
      }
    } // stage('docker build')
    stage('Docker Build couchbase') {
      steps {
        script {
          echo "Building the Couchbase Image"
          sh "docker build -t shreyasgune/sgune-couchbase:${CHANGELOG_VERSION}-${env.BUILD_NUMBER} -f couchbase-test/Dockerfile ."
        }
      }
    } // stage('Docker Build couchbase')
    stage('Moxi-Couchbase Spin up') {
      steps {
        script {
          echo "Creating the couchbase container"
          sh "docker run -d -p 8091:8091 --name=cbase shreyasgune/sgune-couchbase:${CHANGELOG_VERSION}-${env.BUILD_NUMBER}"
          sleep 30
          COUCHBASE_HOST_IP = sh (
            script: "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cbase",
            returnStdout: true
          ).trim()
          println COUCHBASE_HOST_IP

          echo "Initializing the cluster"
          cluster_init = sh (
            script: "docker exec -t cbase couchbase-cli cluster-init -c localhost --cluster-username sgune --cluster-password sgune-cbase --services data --cluster-ramsize 1024",
            returnStdout: true
          ).trim()
          println  cluster_init

          echo "Adding a Memcached Bucket to the couchbase container"
          def bucket_create
          bucket_create = sh (
            script: "docker exec -t --user root cbase couchbase-cli bucket-create -c localhost:8091 --username sgune --password sgune-cbase --bucket test_moxi --bucket-type memcached --bucket-ramsize 1024",
            returnStdout: true
          ).trim()
          println  bucket_create
        }
      }
    } // stage('Moxi-Couchbase Spin up')
    stage('Run Tests') {
      environment {
        GOSS_PATH = "/usr/local/bin/goss"
        GOSS_SLEEP = 2
        GOSS_FILES_STRATEGY = "cp"
      }
      steps {
        script {
          try {
            echo "=====Running Integration Test====="
            sh "dgoss run --privileged=true -p 11211:11211 --name=moxi_container -e COUCHBASE_USER=sgune -e COUCHBASE_PASS=sgune-cbase -e COUCHBASE_HOSTS=${COUCHBASE_HOST_IP} -e COUCHBASE_BUCKET=test_moxi shreyasgune/sgune-moxi:${CHANGELOG_VERSION}-${env.BUILD_NUMBER}"
            sh "docker rm -f cbase"
          } catch (e) {
            sh "docker rm -f cbase"
            throw e
          }
        }
      }
    } // stage('Running Tests')
    stage('Docker Push') {
      when {
        branch 'master'
      }
      steps {
        script {
          echo "Pushing Docker Images"
          sh "docker tag shreyasgune/sgune-moxi:${CHANGELOG_VERSION}-${env.BUILD_NUMBER} shreyasgune/sgune-moxi:${CHANGELOG_VERSION}"
          sh "docker tag shreyasgune/sgune-moxi:${CHANGELOG_VERSION}-${env.BUILD_NUMBER} shreyasgune/sgune-moxi:latest"
          sh "docker push shreyasgune/sgune-moxi:${CHANGELOG_VERSION}"
          sh "docker push shreyasgune/sgune-moxi:latest"
        }
      }
    } // stage('Docker Push')
  }
  post {
    always {
      echo "Renmove the images"
      sh "docker rmi -f shreyasgune/sgune-moxi:${CHANGELOG_VERSION}-${env.BUILD_NUMBER}"
      sh "docker rmi -f shreyasgune/sgune-couchbase:${CHANGELOG_VERSION}-${env.BUILD_NUMBER}"
    }
  }
}