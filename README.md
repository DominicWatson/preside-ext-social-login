# PresideCMS Extension: Social Media Login

This is an extension for [PresideCMS](http://github.com/pixl8/Preside-CMS/) that enables signing up / logging in using third party/social media login such as Facebook, Twitter and Google

## How it works

The extension extends the current Login functionality for Website users in preside to enable them to sign up or login using social media credentials.

You will need to create an application/project on the social media platform from the steps below to obtain API keys for respective platform. The key can be then keyed in in the Social Media Login settings under System > Settings in preside.

### Facebook

Create a Facebook application at https://developers.facebook.com/apps/. The crendentials for Facebook can be obtained from the Facebook application settings.

### Twitter

Create a new Twitter application at https://apps.twitter.com. The credentials for Twitter can be obtained from your Twitter application's Key and Access Tokens

### Google

Create a new project at https://console.developers.google.com/ and create a new OAuth 2.0 client ID and an API Key under credentials.

## Installation

Install the extension to your application via either of the methods detailed below (Git submodule / CommandBox) and then enable the extension by opening up the Preside developer console and entering:

    extension enable preside-ext-social-login
    reload all

### Git Submodule method

From the root of your application, type the following command:

    git submodule add https://github.com/seakchiew/preside-ext-social-login.git application/extensions/preside-ext-social-login

### CommandBox (box.json) method

From the root of your application, type the following command:

    box install seakchiew/preside-ext-social-login

# Reference

This script is based on multiple login script by cfjquery - https://github.com/cfjquery/multiLogin


## Dependency

The Twitter API authentication  uses Twitter4j java library  
Please download the library from http://twitter4j.org/en/index.html and place  twitter4j-core.*.jar into /WEB-INF/lib/ folder in your application


    



