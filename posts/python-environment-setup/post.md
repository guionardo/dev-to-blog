# Python Virtual Environment Setup

Post created at 2022-12-12 10:30

Setting your virtual environment with another python version.

While I'm writing this post, I'm using Ubuntu 22.04 LTS Jammy Jellyfish, wich has python 3.10.

But, I need to work on a project that runs on python 3.8. To assure that the development environment will be the same to the production environment, I have to setup this. I don't want to use docker in this case.

To start, we need to install required packages:

```bash
sudo apt install dirmngr ca-certificates software-properties-common apt-transport-https -y
```

We will use the launchpad PPA's to get things done easely.

Next, we need to install the GPG keys the repositories.

```bash
sudo gpg --list-keys
```
<details><summary>Output</summary>
<pre><code>
gpg: directory '/root/.gnupg' created
gpg: keybox '/root/.gnupg/pubring.kbx' created
gpg: /root/.gnupg/trustdb.gpg: trustdb created
</code></pre>
</details>

Now, wee need to import the GPG key.

```bash
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/deadsnakes.gpg --keyserver keyserver.ubuntu.com --recv-keys F23C5A6CF475977595C89F51BA6932366A755776
```
<details><summary>Output</summary>
<pre>
gpg: key BA6932366A755776: public key "Launchpad PPA for deadsnakes" imported
gpg: Total number processed: 1
gpg:               imported: 1
</pre>
</details>

If no errors, you can continue importing PPA. Use the command below to your installed version:

## Ubuntu 22.04 LTS Jammy Jellyfish

```bash
echo 'deb [signed-by=/usr/share/keyrings/deadsnakes.gpg] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main' | sudo tee -a /etc/apt/sources.list.d/python.list
```

## Ubuntu 20.04 LTS Focal Fossa

```bash
echo 'deb [signed-by=/usr/share/keyrings/deadsnakes.gpg] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu focal main' | sudo tee -a /etc/apt/sources.list.d/python.list
```

## Complete the python3.8 installation:

```bash
sudo apt update && sudo apt install python3.8 python3.8-venv python3.8-python3.8-distutils python3.8-dev python3.8-dbg
```

## Update pip

```bash
python3.8 -m pip install --upgrade pip
```

<details><summary>Output</summary>
<pre>
Defaulting to user installation because normal site-packages is not writeable
Requirement already satisfied: pip in /usr/lib/python3/dist-packages (22.0.2)
Collecting pip
    pip-22.3.1-py3-none-any.whl (2.1 MB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 2.1/2.1 MB 2.5 MB/s eta 0:00:00
Installing collected packages: pip
Successfully installed pip-22.3.1
</pre>
</details>

## Access your project folder on terminal:

```bash
cd ~/dev/my_project
```

## Create your virtual environment

I like to use `.venv` as virtual environment folder name, but you can use `venv` or whatever you want.

```bash
python3.8 -m venv .venv
```

Checking the folder/files created:

```bash
✦ ❯ tree -L 2 .venv
.venv
├── bin
│   ├── activate
│   ├── activate.csh
│   ├── activate.fish
│   ├── Activate.ps1
│   ├── pip
│   ├── pip3
│   ├── pip3.8
│   ├── python -> python3.8
│   ├── python3 -> python3.8
│   └── python3.8 -> /usr/bin/python3.8
├── include
├── lib
│   └── python3.8
├── lib64 -> lib
└── pyvenv.cfg
```

## Activating the virtual environment

Visual Studio Code and another editors can automatically detect the virtual environment and activate it. In the terminal you should do this:

```bash
source .venv/bin/activate
```

And now, you can use the python that you need:

```
❯ python --version
Python 3.8.16
```

## Post-setup

After this, I usually install autopep8 and flake8 for linting/formatting.

```bash
pip install autopep8 flake8
```


Thanks for reading! Leave a comment and click the heart icon!


## Links:

* [How to Install Python 3.8 on Ubuntu 22.04/20.04](https://www.linuxcapable.com/install-python-3-8-on-ubuntu-linux)
