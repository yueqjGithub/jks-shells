properties([[$class: 'JiraProjectProperty'], parameters([[$class: 'JiraVersionParameterDefinition', jiraProjectKey: 'OA', jiraReleasePattern: '', jiraShowArchived: 'false', jiraShowReleased: 'false', name: 'appVersion']])])

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
            name: 'CD_SELECTED_APPLIST',
            quoteValue: false,
            saveJSONParameterToFile: false,
            type: 'PT_CHECKBOX',
            value: env.CD_APPLIST,
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
                    if (env.CD_APPLIST == '') {
                        echo '未设置应用列表'
                        return 1
                    }
                }
            }
        }

        stage('清理构建历史') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_clear_build ${CD_REPO}'
            }
        }

        stage('拉取项目仓库') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_pull_repo ${CD_REPO} ${CD_BRANCH} ${CD_SVN_VERSION}'
            }
        }

        stage('构建应用') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_build_app -a ${CD_SELECTED_APPLIST} -z ${CD_ZIP_ROOT_DIR_NAME} -r ${CD_REAMME}'
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
