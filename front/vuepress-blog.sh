#!/bin/bash
set -x
REPO='myblogtest'
username='zchimp'

mkdir blog
cd blog


current_path=$(pwd)

npm init

npm install -D vuepress
npm install vuepress-theme-reco --save-dev

mkdir docs && echo '# my blog' > docs/README.md
mkdir docs/demo1/ && echo '# my blog demo 1' > docs/demo1/Blog1.md

# 在 package.json 中添加script
jq '.scripts += {
  "docs:dev": "vuepress dev docs",
  "docs:build": "vuepress build docs"
}' package.json > temp.json && mv temp.json package.json


# 在docs目录下创建一个 .vuepress 目录，并创建一个新的config.js文件
cd docs
mkdir .vuepress
cd .vuepress
cat > config.js << EOF
module.exports = {
    title: '$username的个人技术博客',
    description: '',
    base: '/$REPO/',
    theme: "reco",
    themeConfig: {
        nav: [
            { text: '首页', link: '/' },
            { 
                text: '$username的博客', 
                items: [
                    { text: 'Github', link: 'https://github.com/$username' },
                ]
            }
        ],
        sidebar:[
            {
                title: "博客案例1",
                path: "/demo1/Blog1",
                collapsable: false, // 不折叠
                children: [
                    { title: "博客 01", path: "/demo1/Blog1" },
                ],
            }
        ]
    }
}
EOF

cd $current_path

npm run docs:dev
# 确保脚本抛出遇到的错误
# set -e

# 生成静态文件
# npm run docs:build

# 进入生成的文件夹
# cd docs/.vuepress/dist

# git init
# git add -A
# git commit -m 'deploy'

# git push -f git@study.github.com:$username/$REPO.git master:blog-pages
# git push -f git@github.com:你的git名/你的git项目名.git master:你的git分支

# cd $current_path