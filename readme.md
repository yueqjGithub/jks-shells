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

#仓库地址，git仓库末尾需要包含.git
CD_REPO=http://git.avalongames.com/oa_tools/oa_tools.git
#应用列表，根目录为仓库
CD_APPS=FrontEnd,OaToolsManage
#zip包的根目录
CD_ZIP_ROOT=web
#zip包的前缀，运维有强制要求，不配置时默认使用jenkins工程名
CD_ZIP_PREFIX=Web-OaTools
#jira项目的key
CD_JIRA_KEY=OA
#服务器列表
CD_SERVERS=内网测试(user:webuser，ip:192.168.200.217，端口:22，是否sudo:false，部署目录:/online/web/oatools)
#ftp上传地址
CD_FTP_PATH=corp/OaTools

<!-- #项目名称,影响邮件标题和发件人(可选)
CD_PROJECT_NAME=OA工具
#邮件收件人(可选)
CD_MAIL_TO=lvyangxu@avalongames.cn
#邮件抄送人(可选)
CD_MAIL_CC=lvyangxu@avalongames.cn -->