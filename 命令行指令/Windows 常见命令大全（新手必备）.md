# CMD 常见命令大全（新手必备）

本文整理了 Windows CMD（命令提示符）中最常用的命令，按「目录操作、文件操作、系统信息、网络相关、其他实用」五大核心场景分类，每个命令均标注 **用途说明** 和 **实操示例**，适合日常文件管理、环境配置、问题排查等场景，新手可直接对照使用。

## 一、目录操作（核心高频）

用于切换目录、查看目录内容、创建/删除目录，是 CMD 最基础的操作，对应你之前查看目录的需求。

| 命令         | 用途                       | 示例                                                                                    |
| ---------- | ------------------------ | ------------------------------------------------------------------------------------- |
| cd         | 切换当前工作目录（核心命令）           | cd D:\Git_Obsidian （切换到 D 盘的 Git_Obsidian 目录）<br>cd .. （返回上一级目录）<br>cd \ （返回当前磁盘根目录）          |
| dir        | 查看当前目录下的文件/文件夹列表         | dir （默认显示详细信息：名称、大小、修改时间）<br>dir a （显示所有文件，包括隐藏文件，如 .obsidian）dir w （宽格式显示，多列排列，适合文件多的场景） |
| md / mkdir | 创建新文件夹（两个命令功能完全一致）       | md Obsidian_Notes （在当前目录创建 Obsidian_Notes 文件夹）<br>mkdir D:\Temp （在 D 盘根目录创建 Temp 文件夹）     |
| rd / rmdir | 删除空文件夹（rd 是 rmdir 的缩写）   | rd Temp （删除当前目录下的空 Temp 文件夹）rd s Temp （强制删除非空文件夹，会提示确认）                               |
| tree       | 以树形结构显示目录层级（直观查看文件夹嵌套关系） | tree D:\Git_Obsidian （显示指定目录的树形结构）tree f （显示树形结构的同时，列出所有文件）                           |
## 二、文件操作（日常必备）

用于创建、删除、复制、移动文件，以及查看文件内容，适配本地文件管理需求。

|命令|用途|示例|
|---|---|---|
|echo|创建简单文本文件，或输出文本内容|echo "# 我的 Obsidian 笔记" > README.md （创建含指定内容的 README.md 文件）<br>echo 测试内容 （在 CMD 中直接输出“测试内容”）|
|type|查看文本文件的内容（适合小型文本文件）|type README.md （查看当前目录下 README.md 的内容）type D:\Notes\笔记.txt （查看指定路径文件的内容）|
|copy|复制文件到指定位置|copy README.md D:\Backup （将当前目录的 README.md 复制到 D 盘 Backup 文件夹）copy *.txt D:\TextFiles （复制当前目录所有 .txt 文件到指定文件夹）|
|move|移动文件/文件夹（相当于“剪切+粘贴”）|move Notes.txt D:\Obsidian （将当前目录的 Notes.txt 移动到 D 盘 Obsidian 文件夹）<br>move OldFolder NewFolder （将 OldFolder 重命名为 NewFolder，同目录下生效）|
|del|删除文件（注意：删除后无法通过回收站恢复，谨慎使用）|del README.md （删除当前目录的 README.md 文件）del *.log （删除当前目录所有 .log 后缀的文件）del f （强制删除只读文件）|
|ren / rename|重命名文件/文件夹|ren 旧文件名.txt 新文件名.txt （重命名文本文件）<br>ren OldDir NewDir （重命名文件夹）|
## 三、系统信息查看（问题排查）

用于查看系统版本、硬件信息、进程状态等，适合排查环境配置或性能问题。

|命令|用途|示例|
|---|---|---|
|systeminfo|查看系统详细信息（版本、内存、CPU、补丁等）|systeminfo （直接执行，会列出完整系统配置）<br>systeminfo | find "操作系统名称" （筛选显示操作系统版本）|
|tasklist|查看当前运行的所有进程（类似任务管理器的进程列表）|tasklist （显示所有进程的名称、PID、内存占用等）<br>tasklist | find "obsidian" （筛选查看 Obsidian 相关进程）|
|taskkill|结束指定进程（强制关闭无响应程序）|taskkill /f /im obsidian.exe （强制结束 Obsidian 进程）<br>taskkill pid 1234 （通过 PID 结束进程，PID 可从 tasklist 获取）|
|ipconfig|查看网络配置信息（IP 地址、子网掩码、网关等）|ipconfig （基础网络信息）<br>ipconfig all （详细信息，包括 DNS、物理地址等）|
|ver|查看 Windows 系统版本号（简单快速）|ver （直接执行，输出如“Microsoft Windows [版本 10.0.19045.3930]”）|
## 四、网络相关命令（网络排查）

用于测试网络连通性、排查网络故障，适配远程仓库交互（如 Git 推送/拉取）前的网络检查。

|命令|用途|示例|
|---|---|---|
|ping|测试与目标地址的网络连通性（核心网络排查命令）|ping github.com （测试能否连接 GitHub，判断 Git 推送失败是否是网络问题）<br>ping 223.5.5.5 （测试连接阿里云 DNS，排查 DNS 故障）<br>ping -n 5 github.com （发送 5 个数据包，默认发送 4 个）|
|tracert|追踪网络数据包的传输路径（定位网络故障节点）|tracert github.com （查看从本地到 GitHub 服务器的每一跳网络节点，判断哪里中断）|
|nslookup|查询域名对应的 IP 地址（排查 DNS 解析问题）|nslookup github.com （查询 github.com 对应的 IP 地址，确认 DNS 解析是否正常）|
## 五、其他实用命令（提升效率）

包含清屏、环境变量查看、命令历史等，日常使用可提升操作效率。

|命令|用途|示例|
|---|---|---|
|cls|清空 CMD 窗口内容（屏幕杂乱时使用，提升可读性）|cls （直接执行，瞬间清空当前窗口所有内容）|
|history|查看当前 CMD 会话中执行过的所有命令（回溯操作）|history （直接执行，按顺序列出历史命令，可复制重复执行）|
|set|查看或设置系统环境变量（配置 Git、Java 等环境时常用）|set （查看所有环境变量）<br>set PATH （查看 PATH 环境变量，判断 Git 等工具是否配置成功）|
|exit|关闭当前 CMD 窗口|exit （直接执行，快速关闭窗口）|
|help|查看 CMD 命令帮助（忘记命令用法时使用）|help （列出所有 CMD 命令及简要说明）<br>help dir （查看 dir 命令的详细用法和参数说明）|
## 六、新手必备注意事项

1. 命令区分大小写吗？CMD 命令**不区分大小写**（如 cd、CD、Cd 效果一致），但文件/文件夹名称在 Windows 10/11 中默认不区分，部分旧版本或特殊场景可能区分，建议按实际名称输入；

2. 路径输入技巧：输入路径时，可按 **Tab 键** 自动补全（如输入 cd D:\Git_ 后按 Tab，会自动补全为 cd D:\Git_Obsidian，避免手动输入错误）；

3. 危险命令提醒：del 命令删除的文件无法通过回收站恢复，删除前务必确认文件路径和名称正确；rd /s 强制删除文件夹时，会递归删除所有子文件，谨慎使用；

4. 命令参数使用：多数命令后可加参数（如 dir /a、ping -n 5），参数前加“/”或“-”，可通过 help 命令查看具体参数含义（如 help ping）。
> （注：文档部分内容可能由 AI 生成）