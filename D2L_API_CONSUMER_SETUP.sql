/*
Copyright (c) 2017 Holmesglen Institute

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.*/

/*
  CREDITS: Alex Zaytsev, Elias Madi
  
*/


CREATE TABLE D2l_API_TOKEN(
    t_access_token     VARCHAR2(4000),
    t_type             VARCHAR2(256),
    t_scope            VARCHAR2(256),
    t_expires_in       VARCHAR2(256),
    t_refresh_token    VARCHAR2(1024));


CREATE TABLE D2L_API_COOKIES (
    name        VARCHAR2(256),
    value       VARCHAR2(1024),
    domain      VARCHAR2(256),
    expire      DATE,
    path        VARCHAR2(1024),
    secure      VARCHAR2(1),
    version     INTEGER);


CREATE TABLE D2L_API_LOGS (
    log_id              INTEGER,
    log_timestamp       TIMESTAMP,
    log_type            VARCHAR2(4000),
    log_status          VARCHAR2(4000),
    log_message         VARCHAR2(4000),
    log_response        VARCHAR2(4000));


CREATE TABLE D2L_API_CONFIG (
    APICONFID              INTEGER,
    APICONFKEY            VARCHAR2(4000),
    APICONFVALUE           VARCHAR2(4000));

 insert ALL
  into D2L_API_CONFIG values(1,'p_url','https://XXXXX.brightspace.com/d2l/lp/auth/login/login.d2l')
  into D2L_API_CONFIG values(2,'p_login_shib','https://XXXXX..brightspace.com/d2l/shibbolethSSO/lelogin.d2l')
  into D2L_API_CONFIG values(3,'p_login','https://XXXXX.brightspace.com/d2l/lp/auth/login/ProcessLoginActions.d2l')
  into D2L_API_CONFIG values(4,'homePage','https://XXXXX..brightspace.com/index_local.asp')
  into D2L_API_CONFIG values(5,'loginPath','https://XXXXX..brightspace.com/d2l/login')
  into D2L_API_CONFIG values(6,'AuthEndPoint','https://auth.brightspace.com/oauth2/auth') 
  into D2L_API_CONFIG values(7,'tokenEndPt','https://auth.brightspace.com/core/connect/token')
  into D2L_API_CONFIG values(8,'redirectUri','https://localhost:443/callback')
  into D2L_API_CONFIG values(9,'clientID','XXXXX')
  into D2L_API_CONFIG values(10,'clientSecret','XXXXX')
  into D2L_API_CONFIG values(11,'rScope','core:*:* enrollment:*:*')
  into D2L_API_CONFIG values(12,'p_username','<API_USER>')
  into D2L_API_CONFIG values(13,'p_password','<API_USER_PASSWORD>')
  into D2L_API_CONFIG values(14,'api_base_uri','https://XXXXX.brightspace.com/d2l/api/lp/1.10/')
  into D2L_API_CONFIG values(15,'proxyServer','XXXXX')
  into D2L_API_CONFIG values(16,'wallet','file:/XXXXX')
  into D2L_API_CONFIG values(17,'walletPwd','XXXXX')
    
