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
            description: 'svn/git的tag/branch列表',
            remoteURL: env.CD_REPO,
            credentialsId: 'e2972996-6557-42ba-8f14-045b927e177e',
            defaultValue: 'main',
            type: 'PT_BRANCH_TAG',
            listSize: '1'
        )
    }

    stages {
        stage('参数检查') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_check_param'

                script  {
                    // Show the select input
                    env.RELEASE_SCOPE = input message: 'User input required', ok: 'Release!',
                            parameters: [choice(name: 'RELEASE_SCOPE', choices: env.LIST, description: 'What is the release scope?')]
                }
            }
        }

        stage('拉取项目仓库') {
            steps {
                /* groovylint-disable-next-line GStringExpressionWithinString */
                sh 'source ./util.sh && avalon_web_cd_pull_repo ${CD_REPO} ${CD_BRANCH} ${CD_SVN_VERSION}'
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
