properties(
    [
        [$class: 'JiraProjectProperty'], 
        parameters([
            [
                $class: 'JiraVersionParameterDefinition', 
                jiraProjectKey: env.CD_JIRA_KEY, 
                jiraReleasePattern: '', 
                jiraShowArchived: 'false', 
                jiraShowReleased: 'false', 
                name: 'CD_APP_VERSION'
            ]
        ]),
        disableConcurrentBuilds()
    ]
)

pipeline {
    agent {
        node {
            label 'WebJenkins'
        }
    }

    // environment {
    // // CD_GIT_CRED = 'e2972996-6557-42ba-8f14-045b927e177e'
    //     CD_ZIP_ROOT_DIR_NAME= "web"
    // }

    parameters {
        listGitBranches(
            name: 'CD_BRANCH',
            description: 'git的tag/branch列表',
            remoteURL: env.CD_REPO,
            credentialsId: 'e2972996-6557-42ba-8f14-045b927e177e',
            defaultValue: 'main',
            type: 'PT_BRANCH_TAG',
            listSize: '1'
        )

        // jiraVersionParameterDefinition(
        //     name: 'appVersion',
        //     jiraProjectKey: env.CD_JIRA_KEY,
        //     description: 'jira版本号'
        // )

        extendedChoice(
            description: '应用列表',
            multiSelectDelimiter: ',',
            name: 'CD_SELECTED_APPS',
            quoteValue: false,
            saveJSONParameterToFile: false,
            type: 'PT_CHECKBOX',
            value: env.CD_APPS,
            visibleItemCount: 20
        )

        extendedChoice(
            description: '更新到服务器',
            multiSelectDelimiter: ',',
            name: 'CD_SELECTED_SERVERS',
            quoteValue: false,
            saveJSONParameterToFile: false,
            type: 'PT_CHECKBOX',
            value: env.CD_SERVERS,
            visibleItemCount: 20
        )

        text(
            description: '更新说明', 
            name: 'CD_REAMME'
        )
    }

    stages {
        stage('参数检查') {
            steps {
                script {
                    if (env.CD_REPO == '') {
                        echo '未设置仓库http地址'
                        return 1
                    }
                    if (env.CD_BRANCH == '') {
                        echo '未设置仓库分支'
                        return 1
                    }
                    if (env.CD_REPO == 'https://svn*' && env.CD_SVN_VERSION == '' ) {
                        echo '未设置svn版本号'
                        return 1
                    }
                    if (env.CD_APPS == '') {
                        echo '未设置应用列表'
                        return 1
                    }
                }
            }
        }

        stage('清理构建历史') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_clear_build'
            }
        }

        stage('拉取项目仓库') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_pull_repo'
            }
        }

        stage('构建应用') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_build_app'
            }
        }

        stage('更新到服务器') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_update_to_server'
            }
        }        

        stage('测试结果') {
            // input {
            //     message: "测试是否通过"
            //     parameters {
            //         booleanParam(name: 'CD_TEST_SUCCESS', defaultValue: true, description: '测试通过')
            //     }
            // }
            steps {
                script {
                    def CD_TEST_SUCCESS = input(
                        message: '测试是否通过',
                        // parameters : [
                        //     [
                        //         $class: "BooleanParameterDefinition",
                        //         name: 'CD_TEST_SUCCESS',
                        //         description: '测试通过'
                        //     ]
                        // ]
                    )
                }
                sh 'echo 1'
            }
        }
    }

    // post {
    //     // 构建后删除整个工作目录
    //     always {
    //         cleanWs()
    //     }
    // }
}
