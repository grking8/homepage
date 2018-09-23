---
layout: post
title: Encrypt Files With Git Crypt
author: familyguy
comments: true
---

{% include post-image.html name="encrypted-files.png" width="75" height="75" 
alt="encrypted files" %}

Sometimes, for a Git repository in the public domain, you might have certain 
files containing sensitive information that you would like to encrypt.

Or maybe even for a private Git repository, for highly sensitive data, you 
might feel more comfortable if certain files in that repository were encrypted.

In any case, encrypting files in a Git repository can be done via a tool called
[git-crypt.](https://www.agwa.name/projects/git-crypt/)

In this post, we will see how to use git-crypt on macOS / Linux to encrypt
files in a Git hosted repository.

# Prerequisites

- Install Homebrew (macOS only)
- Install GPG (on Linux, this is probably already installed; on macOS, 
`brew install gpg`)
- Install `git-crypt`
    - **Linux**
    - Clone the repo `git clone https://github.com/AGWA/git-crypt.git`
    - `cd /path/to/git-crypt`
    - `make`
    - `git-crypt --version` should work - otherwise `cp /path/to/git-crypt/git-crypt /usr/local/bin`
    - More [installation details](https://github.com/AGWA/git-crypt/blob/master/INSTALL.md)
    - **Mac OS X**
    - `brew install git-crypt`
- A Git repository `<my-repo>` to which you would like to add **new files** to be
encrypted

# Encrypt files

- `cd /path/to/<my-repo>`
- `git-crypt init`
- `touch .gitattributes`
- Specify future files to encrypt in `.gitattributes`

```
<files-to-encrypt> filter=git-crypt diff=git-crypt
```

where `<files-to-encrypt>` follows the same syntax as files specified in 
`.gitignore`
- Add files specified in `.gitattributes` to `<my-repo>` and push up to Git host
- Verify in Git host files are encrypted

# Attention!

The local files are still decrypted. But, there is currently no key to unlock the 
crypt.

This means if the local files are deleted, **you will not be able replace them** (any 
replacements will be encrypted).

Also, without a key, no one else can decrypt the files, e.g if on another 
computer you do `git clone <my-repo>`, the files cannot be 
decrypted. 

As such, it is **highly recommended** the person who originally encrypted the files 
creates the first key for the crypt and unlocks it.

From now on, we will refer to this person as `<crypt-admin>`.

Once `<crypt-admin>` has created the first key and unlocked the crypt, other
authorised users can clone the repository and also decrypt files.

The steps for `<crypt-admin>` to create the first key and unlock the 
crypt are below.

# Create a GPG user

`<crypt-admin>` has to create a _GPG user_ for themselves.

As part of the user creation process, the user will be assigned a public and
private GPG key.

- `gpg --gen-key`
- Enter `<key-type>`, `<key-size>` in bits, `<key-expiration>`
- Enter `<name>`, `<key-description>`, `<email>` 
where `<name>`, `<email>` are known to Git - GPG automatically creates
your `<USER-ID>` from these values
- On macOS, `<key-expiration>` is set to a default and the user is not 
prompted to enter a value. Also, there is no `<key-description>`, but you
can include it in `<name>`
- Enter a passphrase
- On Linux, you might be asked to generate random bytes
    - Open another shell `find / | xargs file`
- Check keys and user have been created `gpg --list-keys`

# Unlock the crypt

- Add `<crypt-admin>`'s GPG user to the crypt `git-crypt add-gpg-user "<USER-ID>"`
- Verify creation of auto-generated commit `Add 1 git-crypt collaborator`
with `git log`
- Push auto-generated commit up to Git host
- `rm -rf /path/to/<my-repo>`
- `git clone <my-repo>`
- Verify files are encrypted
- `git-crypt unlock`
- Enter passphrase
- Verify files are decrypted

# Adding collaborators

`<crypt-admin>` can now unlock the crypt and decrypt files at will!

But what if `<crypt-admin>` wants to be able to do the same from another 
computer?

What if they want to let others, e.g. team members, also decrypt files?

One solution is to pass around `<crypt-admin>`'s GPG keys.

However, it is pretty poor practice to have everyone use the same set 
of keys.

It is probably more acceptable for `<crypt-admin>` to use the same keys on a 
second computer.

But, for the sake of simplicity, let's use the "adding a collaborator" method
for all cases.

(Especially as `<USER-ID>` contains `<key-description>` meaning
`<crypt-admin>` can have, for example, `<USER-ID>` equal to
`James Smith (mac) jsmith@email.com` on one machine and 
`James Smith (PC) jsmith@email.com` on another.)

To be added, a collaborator should

- Satisfy prerequisites
- Create a GPG user for themselves
- `gpg --list-keys`

```
pub 2048R/<public-key-id> 2018-08-30
```
- Export public key to a file `gpg --output <public-key-filename>.gpg --armor --export <public-key-id>`
- Send file to `<crypt-admin>`
- Get `<crypt-admin>` to 
    - Add the collaborator's public key to their key ring `gpg --import /path/to/<public-key-filename>.gpg`
    - `gpg --list-keys`
    - Make the key trustworthy `gpg --edit-key <public-key-id>`
    - At the `gpg>` prompt
        - Enter `sign`
        - Enter `save` (which should exit the prompt)
    - Unlock the crypt `git-crypt unlock`
    - Add the key to the crypt `git-crypt add-gpg-user <public-key-id>`
    - Push auto-generated commit up to Git host
- Pull down `<my-repo>` from Git host
- `git-crypt unlock`
- Verify the files are decrypted
