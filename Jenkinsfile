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
    }

    stages {
        stage('参数设置') {
            steps {
                script {
                    if (env.CD_REPO == null || env.CD_REPO == '') {
                        error '未设置仓库http地址'
                    }

                    if (env.CD_APPS == null || env.CD_APPS == '') {
                        error '未设置应用列表'
                    }
                    if (env.CD_SERVERS == null || env.CD_SERVERS == '') {
                        error '未设置更新服务器列表'
                    }
                    if (env.CD_JIRA_KEY == null || env.CD_JIRA_KEY == '') {
                        error '未设置jira项目key'
                    }

                    if(env.CD_REPO ==~ '.*svn.avalongames.com.*') {
                        echo "仓库类型=svn"
                        env.CD_REPO_TYPE = "svn"
                        if (env.CD_SVN_VERSION == null || env.CD_SVN_VERSION == '') {
                            error '未设置svn版本号'
                        }
                    }
                    if(env.CD_REPO ==~ '.*git.avalongames.com.*') {
                        echo "仓库类型=git"
                        env.CD_REPO_TYPE = "git"
                    }

                    if(env.CD_ZIP_PREFIX == null || env.CD_ZIP_PREFIX == ''){
                        echo "未配置包名前缀，默认使用jenkins工程名称${env.JOB_BASE_NAME}"
                        env.CD_ZIP_PREFIX=env.JOB_BASE_NAME
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

                    buildParams.add(
                        [
                            $class: 'JiraVersionParameterDefinition', 
                            jiraProjectKey: env.CD_JIRA_KEY, 
                            jiraReleasePattern: '', 
                            jiraShowArchived: 'false', 
                            jiraShowReleased: 'false', 
                            name: 'CD_APP_VERSION',
                            description: 'jira版本号'
                        ],
                    )

                    if (env.CD_VERSION_W_DATA == null | env.CD_VERSION_W_DATA == ''){
                        echo '未配置版本号W位，包名不追加该段'
                    }else{
                        def arr = env.CD_VERSION_W_DATA.tokenize(",")
                        buildParams.add(
                            choice(
                                choices: arr, 
                                description: '版本号W位', 
                                name: 'CD_VERSION_W'
                            )
                        )
                    }

                    buildParams.addAll(
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

                    // 自定义参数,(字段名:xx，描述:xx，表单类型:xx，参数值:xx)
                    if (env.CD_CUSTOM_PARAM == null | env.CD_CUSTOM_PARAM == ''){
                        echo "未配置自定义参数，跳过"
                    }else{
                        def arr = env.CD_CUSTOM_PARAM.tokenize(",")
                        for (crow in arr) {
                            def ctype = sh('bash ./custom_string_parse.sh 表单类型')
                            echo ctype
                        }
                    }
                    

                    properties([
                        [$class: 'JiraProjectProperty'], 
                        parameters(buildParams),
                        disableConcurrentBuilds(),
                    ])
               
                    // 分支是参数化构建传递的
                    if (env.CD_BRANCH == null || env.CD_BRANCH == '') {
                        error '未设置仓库分支'
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

                buildName "${env.BUILD_NUMBER}-${env.CD_APP_VERSION}.release"
            }
        }

        stage('上传ftp') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_upload_ftp'
            }            
        }

        // stage('邮件通知') {
        //     when {
        //         allOf {
        //             expression { env.CD_MAIL_TO != null }
        //             expression { env.CD_PROJECT_NAME != null }
        //         }
        //     }
        //     steps {
        //         script {
        //             def body = readFile file: 'email_body.html'
        //             mail body: body, 
        //                  subject: "【${env.CD_PROJECT_NAME}】${env.CD_APP_VERSION}版本Releasenotes", 
        //                  to: env.CD_MAIL_TO,
        //                  cc: env.CD_MAIL_CC
        //         }
        //     }
        // }

//         <!-- #项目名称,影响邮件标题和发件人(可选)
// CD_PROJECT_NAME=OA工具
// #邮件收件人(可选)
// CD_MAIL_TO=lvyangxu@avalongames.cn
// #邮件抄送人(可选)
// CD_MAIL_CC=lvyangxu@avalongames.cn -->

        stage('归档'){
            steps {
                archiveArtifacts artifacts: 'dist/*.releaseinfo', defaultExcludes: false, followSymlinks: false
            }
        }
    }

}
