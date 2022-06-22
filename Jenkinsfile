pipeline {
    agent {
        node {
            label 'WebJenkins'
        }
    }

    environment {
        CD_RELEASE_CRED = 'e2972996-6557-42ba-8f14-045b927e177e'
        CD_FTP_HOST = 'ftp.avalongames.com'
        CD_FTP_USER = 'webuser'
        CD_FTP_PASS = 'vy6Ks348a7s88'
        // CD_ZIP_ROOT_DIR_NAME= "web"
    }

    stages {
        stage('参数设置') {
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
                    if (env.CD_SERVERS == '') {
                        echo '未设置更新服务器列表'
                        return 1
                    }
                    if (env.CD_JIRA_KEY == '') {
                        echo '未设置jira项目key'
                        return 1
                    }

                    if(env.CD_REPO ==~ '.*svn.avalongames.com.*') {
                        echo "仓库类型=svn"
                        env.CD_REPO_TYPE = "svn"
                    }
                    if(env.CD_REPO ==~ '.*git.avalongames.com.*') {
                        echo "仓库类型=git"
                        env.CD_REPO_TYPE = "git"
                    }

                    def buildParams = []

                    if (env.CD_REPO_TYPE == 'git'){
                        buildParams.add(
                            listGitBranches(
                                name: 'CD_BRANCH',
                                description: 'git的tag/branch列表',
                                remoteURL: env.CD_REPO,
                                credentialsId: env.CD_RELEASE_CRED,
                                defaultValue: 'main',
                                type: 'PT_BRANCH_TAG',
                                listSize: '1'
                            )
                        )
                    }
                    if (env.CD_REPO_TYPE == 'svn'){
                        buildParams.addAll(
                            [
                                $class: 'ListSubversionTagsParameterDefinition', 
                                credentialsId: env.CD_RELEASE_CRED, 
                                defaultValue: '', 
                                maxTags: '', 
                                name: 'CD_BRANCH', 
                                reverseByDate: false, 
                                reverseByName: false, 
                                tagsDir: env.CD_REPO, 
                                tagsFilter: ''
                            ],
                            string(defaultValue: 'latest', description: 'svn版本号,latest=最新', name: 'CD_SVN_VERSION')
                        )                        
                    }                    

                    buildParams.addAll(
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
                            name: 'CD_README'
                        )
                    )

                    properties([
                        [$class: 'JiraProjectProperty'], 
                        parameters(buildParams),
                        disableConcurrentBuilds(),
                    ])
               
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

        stage('邮件通知') {
            steps {
                script {
                    if(env.CD_MAIL_TO == '') {
                        echo '未设置收件人,跳过邮件通知'
                    }else{
                        // def body = 'cat ./email_body.html1的撒旦11'
                        def body = readFile file: 'email_body.html'
                        mail body: body, 
                             subject: "【${env.CD_PROJECT_NAME}】${env.CD_APP_VERSION}版本Releasenotes", 
                             to: env.CD_MAIL_TO,
                             cc: env.CD_MAIL_CC,
                             from: "${env.CD_PROJECT_NAME}Release"
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
