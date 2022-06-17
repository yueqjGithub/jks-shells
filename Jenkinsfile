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

    }

    stages {
        stage('参数检查') {
            steps {
                sh '    if [[ ${CD_REPO} == '' ]]; then
                            echo '未设置仓库http地址'
                            return 1
                        fi
                        if [[ ${CD_BRANCH} == '' ]]; then
                            echo '未设置仓库分支'
                            return 1
                        fi
                        if [[ ${CD_REPO} == https://svn* ]] && [[ ${CD_SVN_VERSION} == '' ]]; then
                            echo '未设置svn版本号'
                            return 1
                        fi
                        if [[ ${CD_APPLIST} == '' ]]; then
                            echo '未设置应用列表'
                        fi
                '
            }
        }

        stage('清理上一次构建的残留') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_clear_build ${WORKSPACE}'
            }
        }

        stage('拉取项目仓库') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_pull_repo ${CD_REPO} ${CD_BRANCH} ${WORKSPACE} ${CD_SVN_VERSION}'
            }
        }

        stage('构建应用') {
            steps {
                sh 'source ./util.sh && avalon_web_cd_build_app ${WORKSPACE} ${CD_SELECTED_APPLIST} ${CD_ZIP_ROOT_DIR_NAME}'
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
