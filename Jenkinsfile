// 解析仓库配置，参数为仓库环境变量，返回map类型的list，map格式为[id:xx,url:xx,type:xx]
def parseRepo(repoStr){
    // 遍历仓库
    def repoArr = repoStr.tokenize(",")
    def data = []
    for(row in repoArr){
        def rValue = sh(script:"bash ./custom_string_parse.sh '${row}' ",returnStdout:true).trim()
        def rId = sh(script:"bash ./custom_string_parse.sh '${row}' 仓库id",returnStdout:true).trim()
        def rType = ""          
        if(rValue ==~ '.*svn.avalongames.com.*') {
            rType = "svn"
        }else if(rValue ==~ '.*git.avalongames.com.*') {
            rType = "git"
        }
        def map = [id:rId,url:rValue,type:rType]
        data.add(map)   
    }
    return data
}

// 获取仓库相关的环境变量名称，参数依次为字段名/仓库id
def getRepoFieldEnvName(field,repoId){
    if(repoId != ''){
        field += "_${repoId}"
    }    
    return field
}

def getRepoBranchKey(repoId){
    return getRepoFieldEnvName("CD_BRANCH",repoId)
}

def getRepoSvnVersionKey(repoId){
    return getRepoFieldEnvName("CD_SVN_VERSION",repoId)
}

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

                    def buildParams = []

                    // 遍历仓库
                    def repoData = parseRepo(env.CD_REPO)
                    for(row in repoData){   
                        def branchKey = getRepoBranchKey(row.id)
                        if (row.type == 'git'){
                            def description = 'git的tag/branch列表'
                            if(row.id != ''){
                                description += "(仓库id:${row.id})"
                            }

                            buildParams.add(
                                listGitBranches(
                                    name: branchKey,
                                    description: description,
                                    remoteURL: row.url,
                                    credentialsId: env.CD_RELEASE_CRED,
                                    defaultValue: 'main',
                                    type: 'PT_BRANCH_TAG',
                                    listSize: '1'
                                )
                            )
                        } else if (row.type == 'svn'){
                            def svnVersionKey = getRepoSvnVersionKey(row.id)
                            buildParams.addAll(
                                [
                                    $class: 'ListSubversionTagsParameterDefinition', 
                                    credentialsId: env.CD_RELEASE_CRED, 
                                    defaultValue: '', 
                                    maxTags: '', 
                                    name: branchKey, 
                                    reverseByDate: false, 
                                    reverseByName: false, 
                                    tagsDir: row.url, 
                                    tagsFilter: ''
                                ],
                                string(defaultValue: 'latest', description: 'svn版本号,latest=最新', name: svnVersionKey)
                            )                        
                        }else {
                            error "未识别的仓库类型,地址=${row.url}"
                        }                        
                    }

                    if(env.CD_ZIP_PREFIX == null || env.CD_ZIP_PREFIX == ''){
                        echo "未配置包名前缀，默认使用jenkins工程名称${env.JOB_BASE_NAME}"
                        env.CD_ZIP_PREFIX=env.JOB_BASE_NAME
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

                    if (env.CD_WEB_MODE == null | env.CD_WEB_MODE == ''){
                        echo '未设置web构建模式,默认构建命令npm run release'
                    }else{
                        buildParams.add(
                            def arr = env.CD_WEB_MODE.tokenize(",")
                            choice(
                                choices: arr,
                                description: 'web构建模式',
                                name: 'CD_WEB_MODE'
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

                    // 自定义参数,(字段名:xx，描述:xx，表单类型:xx，默认值:xx(仅input、checkbox时生效)，选项:xx)
                    if (env.CD_CUSTOM_PARAM == null | env.CD_CUSTOM_PARAM == ''){
                        echo "未配置自定义参数，跳过"
                    }else{
                        def arr = env.CD_CUSTOM_PARAM.tokenize(",")
                        for (cRow in arr) {
                            def cName = sh(script:"bash ./custom_string_parse.sh '${cRow}' 字段名",returnStdout:true).trim()
                            def cDesc = sh(script:"bash ./custom_string_parse.sh '${cRow}' 描述",returnStdout:true).trim()                            
                            def cType = sh(script:"bash ./custom_string_parse.sh '${cRow}' 表单类型",returnStdout:true).trim()
                            def cDefaultValue = sh(script:"bash ./custom_string_parse.sh '${cRow}' 默认值",returnStdout:true).trim() 
                            def cOption = sh(script:"bash ./custom_string_parse.sh '${cRow}' 选项",returnStdout:true).trim()

                            echo "自定义参数解析成功,字段名=${cName},描述=${cDesc},类型=${cType}，默认值=${cDefaultValue},选项=${cOption}"

                            if (cType == 'input') {                               
                                buildParams.add(
                                    string(
                                        defaultValue: cDefaultValue, 
                                        description: cDesc, 
                                        name: cName,
                                        trim: true
                                    )
                                )
                            } else if (cType == 'single-select'){
                                cOption = cOption.tokenize("|")
                                buildParams.add(
                                    choice(
                                        choices: cOption, 
                                        description: cDesc, 
                                        name: cName
                                    )
                                )
                            } else if (cType == 'multiple-select') {
                                // 多选插件无法识别分隔符参数multiSelectDelimiter='|'，原因未知
                                cOption = cOption.tokenize("|").join(",")
                                buildParams.add(
                                    extendedChoice(
                                        description: cDesc,
                                        multiSelectDelimiter: ',',
                                        name: cName,
                                        quoteValue: false,
                                        saveJSONParameterToFile: false,
                                        type: 'PT_CHECKBOX',
                                        value: cOption,
                                        visibleItemCount: 20
                                    )
                                )
                            } else if (cType == 'checkbox'){
                                buildParams.add(
                                    booleanParam(
                                        defaultValue: cDefaultValue == 'true', 
                                        description: cDesc, 
                                        name: cName
                                    )
                                )                                
                            } else {
                                error "不支持的自定义参数类型,${cName}的类型=${cType}"
                            }
                            
                        }
                    }
                    

                    properties([
                        [$class: 'JiraProjectProperty'], 
                        parameters(buildParams),
                        disableConcurrentBuilds(),
                    ])
               
                    // 分支是参数化构建传递的，参数化构建的值最后进行检测      
                    for(row in repoData){   
                        def branchKey = getRepoBranchKey(row.id)
                        def branch = env."${branchKey}"
                        if(branch== null || branch == ""){
                            error "未设置仓库(id=${row.id})的分支"
                        }

                        if(row.type == 'svn') {
                            def svnVersionKey = getRepoSvnVersionKey(row.id)
                            def svnVersion = env."${svnVersionKey}"
                            if (svnVersion == null || svnVersion == '') {
                                error '未设置svn版本号'
                            }
                        }
                    }

                }
            }
        }

        stage('拉取项目仓库') {
            steps {
                script{
                    def repoData = parseRepo(env.CD_REPO)
                    for(row in repoData){
                        def branchKey = getRepoBranchKey(row.id)
                        def svnVersionKey = getRepoSvnVersionKey(row.id)
                        def svnVersion = env."${svnVersionKey}"
                        if( svnVersion == null ){
                            svnVersion = ""
                        }
                        def branch = env."${branchKey}"

                        sh "source ./util.sh && avalon_web_cd_pull_repo ${row.type} ${branch} ${row.url} \"${svnVersion}\""
                    }
                }         
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

        stage('归档'){
            steps {
                archiveArtifacts artifacts: 'dist/*.releaseinfo', defaultExcludes: false, followSymlinks: false
            }
        }
    }

}
