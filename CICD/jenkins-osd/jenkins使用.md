```groovy
pipeline {
    agent any
    environment {
        // 私有仓库地址，末尾带项目仓库名
        REGISTRY = "harbor.test.com/library"
        // 镜像名
        IMAGE_NAME = "demo-app"
        // 镜像tag：使用git短commit
        IMAGE_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
        // 凭证ID
        DOCKER_CRED = credentials('harbor-auth')
    }
    stages {
        stage('1. 拉取代码') {
            steps {
                echo "代码已自动拉取"
            }
        }
        stage('2. 登录私有仓库') {
            steps {
                sh """
                echo ${DOCKER_CRED_PSW} | docker login ${REGISTRY} -u ${DOCKER_CRED_USR} --password-stdin
                """
            }
        }
        stage('3. 构建Docker镜像') {
            steps {
                sh """
                docker build -t ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }
        stage('4. 推送镜像到私有仓库') {
            steps {
                sh """
                docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }
    }
    post {
        always {
            // 登出仓库，清理缓存
            sh "docker logout ${REGISTRY}"
            // 删除本地镜像释放空间
            sh "docker rmi ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        }
    }
}
```