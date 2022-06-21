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

  

    stages {
        stage('参数检查') {
            steps {
                script {
                    properties(
                        [
                            [$class: 'JiraProjectProperty'], 
                            parameters([
                                listGitBranches(
                                    name: 'CD_BRANCH',
                                    description: 'git的tag/branch列表',
                                    remoteURL: env.CD_REPO,
                                    credentialsId: 'e2972996-6557-42ba-8f14-045b927e177e',
                                    defaultValue: 'main',
                                    type: 'PT_BRANCH_TAG',
                                    listSize: '1'
                                ),
                                [
                                    $class: 'JiraVersionParameterDefinition', 
                                    jiraProjectKey: env.CD_JIRA_KEY, 
                                    jiraReleasePattern: '', 
                                    jiraShowArchived: 'false', 
                                    jiraShowReleased: 'false', 
                                    name: 'CD_APP_VERSION',
                                    description: 'jira版本号'
                                ],
                                extendedChoice(
                                    description: '应用列表',
                                    multiSelectDelimiter: ',',
                                    name: 'CD_SELECTED_APPS',
                                    quoteValue: false,
                                    saveJSONParameterToFile: false,
                                    type: 'PT_CHECKBOX',
                                    value: env.CD_APPS,
                                    visibleItemCount: 20
                                ),
                                extendedChoice(
                                    description: '更新到服务器',
                                    multiSelectDelimiter: ',',
                                    name: 'CD_SELECTED_SERVERS',
                                    quoteValue: false,
                                    saveJSONParameterToFile: false,
                                    type: 'PT_CHECKBOX',
                                    value: env.CD_SERVERS,
                                    visibleItemCount: 20
                                ),
                                text(
                                    description: '更新说明', 
                                    name: 'CD_REAMME'
                                ),
                            ]),
                            disableConcurrentBuilds()
                        ]
                    )

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
                    if (env.CD_SERVERS == '') {
                        echo '未设置更新服务器列表'
                        return 1
                    }
                    if (env.CD_JIRA_KEY == '') {
                        echo '未设置jira项目key'
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
            steps {
                input(
                    message: '测试通过',
                )
            }
        }

        stage('上传ftp') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_upload_ftp'
            }            
        }

        stage('通知') {
            parallel{
                stage('通知1-钉钉群'){
                    steps {
                        sh 'echo 111'
                    } 
                }
                stage('通知2-邮件'){
                    steps {
                        sh 'echo 222'
                    } 
                }
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
