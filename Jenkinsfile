
def APPS = []
def REPO_PUSH = []

pipeline {

    agent {
        kubernetes {
            label 'docker'
            defaultContainer 'jnlp'
            yaml """
                apiVersion: v1
                kind: Pod
                metadata:
                  labels:
                    app: jenkins-docker
                spec:
                  containers:
                  - name: docker
                    image: docker:18.09.0-git
                    command:
                    - cat
                    tty: true
                    volumeMounts:
                    - mountPath: /var/run/docker.sock
                      name: docker-sock
                  - name: gradle
                    image: gradle:5.4.1-jdk8
                    command:
                    - cat
                    tty: true
                  volumes:
                  - name: docker-sock
                    hostPath:
                      path: /var/run/docker.sock
                """
        }
    }

    environment {
        GITHUB_HOOK_SECRET = ""
        DOCKERHUB = credentials('dockerhub-credentials')
        DOCKERHUB_USR = credentials('dockerhub-user')
        DOCKERHUB_PSW = credentials('dockerhub-password')
    }

    stages {

        stage("Find app name to build") {
            steps {
                script {
                    if (REF != "") {
                        VALUESFILE = sh(returnStdout: true, script:"git show -m --name-only --pretty=''")
                        LIST = VALUESFILE.split('\n')
                        def MAP = [:]
                        for(String file in LIST) {
                            FILE_PARTS = file.split('/')
                            if(FILE_PARTS.size() > 1){
                                MAP.put(FILE_PARTS[0], "build")
                            }
                        }
                        APPS = MAP.keySet()
                        echo "${APPS}"
                    }
                }
                echo "Changes in:${VALUESFILE}"
                echo "application to build:${APPS}"
            }
        }

        stage("Build and testing") {
            steps {
                container("gradle") {
                    script {
                        for (String app in APPS) {
                            TO_BUILD_REPO = sh(
                                    script: "ls ${app}/Dockerfile",
                                    returnStatus: true
                            )
                            if (TO_BUILD_REPO == 0) {
                                sh "gradle ${app}:clean ${app}:build -x test --refresh-dependencies"
                            }
                            TO_SONAR_TEST = sh(
                                    script: "ls ${app}/sonar-project.properties",
                                    returnStatus: true
                            )
                            if (TO_SONAR_TEST == 0) {
                                def scannerHome = tool 'sonar3'
                                withSonarQubeEnv('SonarQube') {
                                    dir("${app}") {
                                        sh "${scannerHome}/bin/sonar-scanner"
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }
        stage("Build and push docker image") {
            steps {
                container("docker") {
                    script {
                        sh "docker login -u $DOCKERHUB_USR -p $DOCKERHUB_PSW"
                        for(String app in APPS) {
                            TO_BUILD = sh (
                                    script: "ls ${app}/Dockerfile",
                                    returnStatus: true
                            )
                            if (TO_BUILD == 0) {
                                env.DATE_BUILD = new Date().format('yyyyMMddhhmm')
                                env.APP = app
                                sh """
                                docker build ./${APP}/ -t project-name/sp-${APP}:1.0.1.${DATE_BUILD} 
                                docker push project-name/sp-${APP}:1.0.1.${DATE_BUILD}
                                docker rmi project-name/sp-${APP}:1.0.1.${DATE_BUILD}
                                """
                            }
                        }
                        sh "docker logout"
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}