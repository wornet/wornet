# [Wornet](https://www.wornet.net)

Social Network

# Install

You can install Wornet locally for test and development purpose this way:
- [Install nodejs](https://nodejs.org)
- [Install mongodb](https://www.mongodb.com)
- [Install redis](https://redis.io)
- [Install GIT](https://git-scm.com)
- [Install ImageMagick](http://www.imagemagick.org/script/download.php)
- Clone Wornet and install dependencies:
```shell
git clone https://github.com/wornet/wornet.git
npm install
```
You can customize your local settings by creating a **custom.json** file the **config** directory. You need it to set up a mail sender for example in order to test mail sends.

Now you can start local server with:
```npm run dev```

Then you can test it in your browser at http://localhost:8000

For a production environement, we recommand you serve it throught pm2 on HTTPS protocole.
