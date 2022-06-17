/* groovylint-disable-next-line CompileStatic */
pipeline {
    agent {
        node {
            label 'WebJenkins'
        }
    }

    // environment {
    // // CD_GIT_CRED = 'e2972996-6557-42ba-8f14-045b927e177e'
    // }

    parameters {
        listGitBranches(
            name: 'CD_BRANCH',
            description: 'git的tag/branch列表',
            remoteURL: env.CD_REPO,
            // credentialsId: 'e2972996-6557-42ba-8f14-045b927e177e',
            credentialsId: withCredentials([usernamePassword(credentialsId: 'avalon.dev.release.web')]),
            defaultValue: 'main',
            type: 'PT_BRANCH_TAG',
            listSize: '1'
        )
    }

    stages {
        stage('参数检查') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_check_param'
            }
        }

        stage('拉取项目仓库') {
            steps {
                /* groovylint-disable-next-line GStringExpressionWithinString */
                sh 'source ./util.sh && avalon_web_cd_pull_repo ${CD_REPO} ${CD_BRANCH} ${CD_SVN_VERSION}'
            }
        }

        stage('构建应用') {
            steps {
                /* groovylint-disable-next-line GStringExpressionWithinString */
                sh 'source ./util.sh && avalon_web_cd_build_app ${CD_APPLIST}'
            }
        }
    }

    post {
        // 构建后删除整个工作目录
        always {
            cleanWs()
        }
    }
}
