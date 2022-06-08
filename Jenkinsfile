

pipeline {

    agent {
        node {
            label 'WebJenkins'
        }
    }

    environment {
        CD_GIT_CRED = 'e2972996-6557-42ba-8f14-045b927e177e'
    }

    parameters {
    //     // when {
    //     //     expression {
    //     //         return env.CD_REPO.contains("git.avalongames.com")
    //     //     }
            
            listGitBranches(
                name: 'CD_BRANCH',
                description: 'svn/git的tag/branch列表',
                remoteURL: env.CD_REPO,
                credentialsId: 'e2972996-6557-42ba-8f14-045b927e177e',
                defaultValue: 'main',
                type: 'PT_BRANCH_TAG',
            )
    //     // }
 
    }

    stages {
        stage('参数检查') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_check_param'
            }
        }

        stage('参数安装') {
            steps {
                script {
                    properties([
                        parameters([
                            choice(
                                choices: ['ONE', 'TWO'], 
                                name: 'PARAMETER_01'
                            ),
                            booleanParam(
                                defaultValue: true, 
                                description: '', 
                                name: 'BOOLEAN'
                            ),
                            text(
                                defaultValue: '''
                                this is a multi-line 
                                string parameter example
                                ''', 
                                 name: 'MULTI-LINE-STRING'
                            ),
                            string(
                                defaultValue: 'scriptcrunch', 
                                name: 'STRING-PARAMETER', 
                                trim: true
                            )
                        ])
                    ])
                }
            }
        }

        stage('拉取项目仓库') {
            steps {
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
