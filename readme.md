## 开发相关

### pipeline语法校验
+ 地址 https://newjenkins.avalongames.com/pipeline-model-converter/validate
+ 快捷键 shift + alt + v

## 开始使用

### 使用条件
+ jenkins项目必须时pipeline类型的
+ 只适应于web平台内部项目，目前支持web前端，node后端应用，laravel应用，java应用，未识别的类型不做额外处理
+ 代码仓库只支持公司svn或公司git
+ 更新应用时，node应用需要在应用同级目录配置一个同名的pm2配置文件*.json作为启动/停止脚本，比如IAMManage和IAMManage.json
+ java应用需要在应用的根目录下配置一个同名的业务配置文件*.properties，比如SuperSDK/SuperSDK.jar和SuperSDK/SuperSDK.properties

### 使用教程
+ 每个应用支持自定义脚本，执行路径为应用根目录/custom-build/build.sh，在压缩成zip前执行
+ 需要根据项目实际情况，在打包工程设置以下环境变量
    + ftpPath
    + appSvnDir
    + branch
    + appList 应用列表，必须为相对分支路径的全路径，比如BackEnd/IAMManage和web/FrontEnd/avalon-gbs-util-client
    + updateTarget 注意冒号为英文逗号，逗号为中文逗号
    + customShellPath 自定义脚本路径，可选参数，在压缩成zip和生成md5前执行

#仓库地址，git仓库末尾需要包含.git
CD_REPO=http://git.avalongames.com/oa_tools/oa_tools.git
#应用列表，根目录为仓库
CD_APPLIST=FrontEnd,OaToolsManage
#zip包的根目录
CD_ZIPROOT=web
#jira项目的key
CD_JIRAKEY=OA
#服务器列表
CD_SERVERLIST=内网测试(ip:192.168.200.217，端口:22，是否sudo:false，部署目录:/online/web/oatools)