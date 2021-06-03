# Git

## 生成ssh公钥

Git服务器可以使用SSH公钥进行认证，用户的SSH密钥保存在**.ssh**目录下，

- 根目录创建.ssh文件夹
- 执行`ssh-keygen -o`命令
- 不指定存储位置、密钥密码，按三次回车
- 此时**.ssh**目录下**id_rsa.pub**就是ssh公钥，将其复制在GitHub的SSH Keys里面即可

