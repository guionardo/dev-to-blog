# Python Virtual Environment Setup

Post created at 2022-12-12 10:30

Setting your virtual environment with another python version.

I'm using Ubuntu 220.04 LTS Jammy Jellyfish, wich has python 3.10.

But, I need to work on a project that runs on python 3.8. To assure that the development environment will be the same to the production environment, I have to setup this.

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


## Links:

* [How to Install Python 3.8 on Ubuntu 22.04/20.04](https://www.linuxcapable.com/install-python-3-8-on-ubuntu-linux)
* 