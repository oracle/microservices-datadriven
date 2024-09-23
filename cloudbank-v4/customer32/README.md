# Example of Spring application using the JDBCClient and Oracle database starters

This application runs on [Oracle Backend for Microservices and AIs](https://cloudmarketplace.oracle.com/marketplace/en_US/listing/138899911). 

**NOTE:** The application assumes that the `customer` application has been deployed as it shares the same user in the database.

## Build the application

In the `customer32` directory execute `mvn clean package`.

## Deploy the application to Oracle Backend for Microservices and AI

1. Create a tunnel to the OBaaS admin service

    ```shell
    kubectl port-forward -n obaas-admin svc/obaas-admin 8080
    ```

1. Get the `obaas-admin` users password

    ```shell
    kubectl get secret -n azn-server oractl-passwords -o jsonpath='{.data.admin}' | base64 -d
    ```

1. Start `oractl` and login as the `obaas-admin` user using the `connect` command.

    ```text
        _   _           __    _    ___
    / \ |_)  _.  _. (_    /  |   |
    \_/ |_) (_| (_| __)   \_ |_ _|_
    ========================================================================================
    Application Name: Oracle Backend Platform :: Command Line Interface
    Application Version: (1.1.1)
    :: Spring Boot (v3.2.1) ::
    Ask for help:
        - Slack: https://oracledevs.slack.com/archives/C03ALDSV272
        - email: obaas_ww@oracle.com
    oractl:>connect
    ? username obaas-admin
    ? password *************
    Credentials successfully authenticated! obaas-admin -> welcome to OBaaS CLI.
    oractl:>
    ```

1. Create the binding for the application using this command `bind --service-name customer32 --username customer`

    ```text
    oractl:>bind --service-name customer32 --username customer
    ? Database/Service Password *************
    Schema {customer} was successfully Created and Kubernetes Secret {application/customer32} was successfully Created.
    ```

1. Deploy the application using this command `deploy --service-name customer32 --artifact-path target/customer32-0.0.1-SNAPSHOT.jar --image-version 0.0.1 --liquibase-db admin`

    ```text
    oractl:>deploy --service-name customer32 --artifact-path target/customer32-0.0.1-SNAPSHOT.jar --image-version 0.0.1 --liquibase-db admin
    ```

## Create route for the application in Apache APISIX API Gateway

1. Get Apache APISIX Gateway Admin Key

    ```shell
    kubectl -n apisix get configmap apisix -o yaml
    ```

1. Create tunnel to Apache APISIX

    ```shell
    kubectl port-forward -n apisix svc/apisix-admin 9180
    ```

1. Create route

    In the CloudBank directory run the following command. *NOTE*, you must add the API-KEY to the command

    ````shell
    (cd ../apisix-routes; source ./create-customer32-route.sh <YOUR-API-KEY>)
    ```

## Test the application

1. Get the external IP address

    ```shell
    kubectl -n ingress-nginx get service ingress-nginx-controller
    ```

    Make a note of the `EXTERNAL-IP` it will be used in the tests below.

    ```text
    NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                      AGE
    ingress-nginx-controller   LoadBalancer   10.96.172.148   146.235.207.230   80:31393/TCP,443:30506/TCP   158m

1. List all customers

    ```shell
    curl -s http://<EXTERNAL-IP>/api/v2/customer | jq
    ```

    Returns:

    ```text
    [{"id":"qwertysdwr","name":"Andy","email":"andy@andy.com"},{"id":"aerg45sffd","name":"Sanjay","email":"sanjay@sanjay.com"},{"id":"bkzLp8cozi","name":"Mark","email":"mark@mark.com"},{"id":"mtrouncer0","name":"O'Kon, Murazik and Ruecker","email":"mfaiers0@jalbum.net"},{"id":"jwashington1","name":"Halvorson, Jaskolski and Murray","email":"mdandrea1@hhs.gov"},{"id":"tdufaur2","name":"Conn Inc","email":"mrittelmeyer2@jiathis.com"},{"id":"tgrimolbie3","name":"Halvorson Group","email":"lfrediani3@icq.com"},{"id":"bbowring4","name":"Collins Inc","email":"flitt4@studiopress.com"},{"id":"dantcliff5","name":"Cronin, Bernhard and Fritsch","email":"sstutte5@about.com"},{"id":"ldrake6","name":"Haag Inc","email":"fjuett6@samsung.com"},{"id":"bnewlove7","name":"Hegmann, Block and Treutel","email":"crippingale7@hatena.ne.jp"},{"id":"disland8","name":"Kunze, Price and Balistreri","email":"pricardot8@jiathis.com"},{"id":"ecornell9","name":"Durgan, Beahan and Sanford","email":"gmacelroy9@php.net"},{"id":"hcluelowa","name":"Howell-Strosin","email":"mkerkhama@acquirethisname.com"},{"id":"kmackenb","name":"Klocko-Pfannerstill","email":"dhaineyb@hibu.com"},{"id":"kcoultc","name":"Schumm-Haag","email":"dwhittamc@umn.edu"},{"id":"ksparwelld","name":"Greenholt-Deckow","email":"jbanaszczykd@hc360.com"},{"id":"hkhomiche","name":"Abshire-Hackett","email":"kentreise@ox.ac.uk"},{"id":"klisimoref","name":"Boyle LLC","email":"swynchf@google.es"},{"id":"ejanewayg","name":"Stracke LLC","email":"tkernang@shop-pro.jp"},{"id":"jfiddianh","name":"Balistreri LLC","email":"ptippetth@yolasite.com"},{"id":"bfouracresi","name":"Johnson, Turner and Mayert","email":"hgommowei@hugedomains.com"},{"id":"mcoleiroj","name":"Walsh Group","email":"cgoodhallj@google.it"},{"id":"mnavarijok","name":"Monahan, Corwin and Klein","email":"jbernocchik@flavors.me"},{"id":"fcorryl","name":"Schamberger and Sons","email":"swilcel@facebook.com"},{"id":"cshillakerm","name":"Schaden Group","email":"kcamackem@reverbnation.com"},{"id":"fnelligann","name":"Rau, O'Hara and Vandervort","email":"mkneeshawn@simplemachines.org"},{"id":"kmonteso","name":"Waters Inc","email":"dbyatto@merriam-webster.com"},{"id":"mbeeckerp","name":"Rice and Sons","email":"gcoxp@rediff.com"},{"id":"klindblomq","name":"Purdy-Kohler","email":"belsmereq@springer.com"},{"id":"nayshfordr","name":"Lueilwitz-Schmeler","email":"bcamberr@live.com"},{"id":"bglencross","name":"Schoen, Hartmann and Nolan","email":"rbroomfields@cocolog-nifty.com"},{"id":"mdomenct","name":"Purdy-Ferry","email":"bchancet@wp.com"},{"id":"psummerlyu","name":"Cole Group","email":"vdurlingu@wsj.com"},{"id":"hsturmanv","name":"Hauck-Waters","email":"tnolinv@zdnet.com"},{"id":"lmarlonw","name":"Breitenberg-Dickens","email":"cmurgatroydw@elpais.com"},{"id":"uorumx","name":"Bogisich, Dietrich and Kris","email":"rfowlex@mozilla.com"},{"id":"ndunstoney","name":"Reichel Inc","email":"bcausticky@mapquest.com"},{"id":"zlavrinovz","name":"Block-Leannon","email":"wscottesmoorz@un.org"},{"id":"cscrivin10","name":"Gottlieb-Romaguera","email":"pinderwick10@so-net.ne.jp"},{"id":"glefridge11","name":"Breitenberg Inc","email":"ehrishchenko11@photobucket.com"},{"id":"bmorsey12","name":"Moore, Bernhard and Witting","email":"kcasiero12@sina.com.cn"},{"id":"jmurrhardt13","name":"Balistreri-Harvey","email":"dhows13@biglobe.ne.jp"},{"id":"fmedlen14","name":"Hackett-Weissnat","email":"kchelsom14@ftc.gov"},{"id":"hfarnish15","name":"Oberbrunner, Schmidt and Bailey","email":"cthake15@adobe.com"},{"id":"srignold16","name":"Spencer-Mitchell","email":"idye16@reuters.com"},{"id":"acroysdale17","name":"Mohr-Turcotte","email":"mmacsween17@multiply.com"},{"id":"truslin18","name":"Fay LLC","email":"rbeetles18@reddit.com"},{"id":"rlegrand19","name":"Olson, Mohr and Kuphal","email":"tcecchi19@mediafire.com"},{"id":"cnenci1a","name":"Bechtelar LLC","email":"dkas1a@hp.com"},{"id":"ccartmale1b","name":"Feest, Hartmann and Schmidt","email":"rmelbourne1b@discovery.com"},{"id":"twoolen1c","name":"Shields, Lockman and Schinner","email":"eavis1c@alexa.com"},{"id":"bsmiley1d","name":"Kozey-Bayer","email":"mderrington1d@webs.com"},{"id":"lorring1e","name":"Fisher Inc","email":"wpenchen1e@nih.gov"},{"id":"mcardnell1f","name":"Bayer-Wehner","email":"rburborough1f@feedburner.com"},{"id":"vpolon1g","name":"Tromp Inc","email":"bknappe1g@ycombinator.com"},{"id":"nhapgood1h","name":"Stanton-Stokes","email":"ihallatt1h@nyu.edu"},{"id":"ymcrory1i","name":"McGlynn, Pagac and Herzog","email":"ttraise1i@bizjournals.com"},{"id":"dallday1j","name":"Kuhlman Inc","email":"mtower1j@tinyurl.com"},{"id":"kcarmen1k","name":"Gottlieb-Parker","email":"bstarkey1k@behance.net"},{"id":"ileedal1l","name":"Runolfsson-Nader","email":"elittlepage1l@issuu.com"},{"id":"lgenty1m","name":"Beahan LLC","email":"cmelvin1m@ibm.com"},{"id":"cgadie1n","name":"Hyatt Inc","email":"gstove1n@reference.com"},{"id":"hsantorini1o","name":"Prohaska Inc","email":"rcrux1o@twitpic.com"},{"id":"rbedwell1p","name":"Padberg Inc","email":"fbrilon1p@baidu.com"},{"id":"rtramel1q","name":"Smith Inc","email":"gfoxhall1q@imdb.com"},{"id":"vbuggy1r","name":"Anderson-Ruecker","email":"fshambroke1r@list-manage.com"},{"id":"ffulstow1s","name":"Miller, Keebler and Davis","email":"econklin1s@discuz.net"},{"id":"tjiggen1t","name":"Runolfsdottir and Sons","email":"aozelton1t@craigslist.org"},{"id":"skebell1u","name":"Strosin and Sons","email":"eauchinleck1u@columbia.edu"},{"id":"wwhapple1v","name":"Johns, Paucek and Heidenreich","email":"rdedmam1v@bing.com"},{"id":"creubel1w","name":"Bernier, Beier and Bogisich","email":"crotchell1w@is.gd"},{"id":"nchaston1x","name":"Bogisich-Hessel","email":"wbransom1x@cafepress.com"},{"id":"lscibsey1y","name":"Hammes and Sons","email":"seastway1y@xing.com"},{"id":"wwareing1z","name":"Hilll Group","email":"gsaiger1z@omniture.com"},{"id":"jhans20","name":"Nitzsche, Greenfelder and DuBuque","email":"cpeppin20@cisco.com"},{"id":"hhuffadine21","name":"Steuber and Sons","email":"adongall21@yahoo.com"},{"id":"amapson22","name":"Krajcik-Schiller","email":"rgrimmolby22@csmonitor.com"},{"id":"droadknight23","name":"Dietrich, Reynolds and Gleason","email":"pbalmer23@huffingtonpost.com"},{"id":"hwinckle24","name":"Windler, Rau and Aufderhar","email":"jambrosini24@cdc.gov"},{"id":"eivermee25","name":"Huels, Homenick and Marvin","email":"gosmar25@constantcontact.com"},{"id":"drait26","name":"Botsford-Goodwin","email":"tseiter26@cpanel.net"},{"id":"rsherington27","name":"Stokes-DuBuque","email":"dtaile27@mail.ru"},{"id":"rkubicek28","name":"Bruen Group","email":"nrusse28@imdb.com"},{"id":"bblucher29","name":"Koss and Sons","email":"btowse29@cbsnews.com"},{"id":"hhegden2a","name":"Crona Group","email":"mkillcross2a@nbcnews.com"},{"id":"aguilford2b","name":"Stroman LLC","email":"sporkiss2b@blog.com"},{"id":"rmayall2c","name":"McClure-Carroll","email":"tevered2c@trellian.com"},{"id":"cblaschke2d","name":"Brekke, Hagenes and Kihn","email":"nscobbie2d@bravesites.com"},{"id":"kelsay2e","name":"Hilll-Dicki","email":"aaartsen2e@google.de"},{"id":"fcasella2f","name":"Labadie, Dooley and Bruen","email":"ifritschel2f@mail.ru"},{"id":"ttregensoe2g","name":"Bailey, Stroman and Abernathy","email":"mbatting2g@ezinearticles.com"},{"id":"lmorrison2h","name":"Walter-Wunsch","email":"kguswell2h@cmu.edu"},{"id":"ppelos2i","name":"Reinger, Adams and Torphy","email":"ecalderon2i@wufoo.com"},{"id":"mmalatalant2j","name":"Hansen-Connelly","email":"zrodie2j@rakuten.co.jp"},{"id":"awyeth2k","name":"O'Hara and Sons","email":"dvallens2k@washington.edu"},{"id":"ppalfree2l","name":"Johns, Hackett and Olson","email":"hpaffitt2l@squidoo.com"},{"id":"hscouler2m","name":"Graham-Hand","email":"galliston2m@kickstarter.com"},{"id":"dcoath2n","name":"Wilkinson-Sauer","email":"mwathan2n@de.vu"},{"id":"lcosgriff2o","name":"Ratke-VonRueden","email":"mnisco2o@furl.net"},{"id":"lgoodwill2p","name":"Lebsack Group","email":"cbattista2p@mtv.com"},{"id":"hcrockatt2q","name":"Crona, Berge and Hahn","email":"rstainbridge2q@europa.eu"},{"id":"wgeorgiev2r","name":"Medhurst Inc","email":"ichedzoy2r@wikimedia.org"}]
    ```

1. Find a customer

    ```shell
    curl -i -X GET 'http://<EXTERNAL-IP>/api/v2/customer/name/Walsh%20Group
    ```

    Returns:

    ```text
    HTTP/1.1 200
    Date: Wed, 14 Feb 2024 17:59:00 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive

    {"id":"mcoleiroj","name":"Walsh Group","email":"cgoodhallj@google.it"}
    ```

1. Find a customer by ID

    ```shell
    curl -i -X GET 'http://<EXTERNAL-IP>/api/v2/customer/lcosgriff2o'
    ```

    Returns:

    ```text
    HTTP/1.1 200
    Date: Wed, 14 Feb 2024 18:01:33 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive

    {"id":"lcosgriff2o","name":"Ratke-VonRueden","email":"mnisco2o@furl.net"}
    ```

1. Find a customer by E-mail

    ```shell
    curl -i -X GET 'http://<EXTERNAL-IP>/api/v2/customer/email/cgoodhallj%40google.it'
    ```

    Returns:

    ```text
    HTTP/1.1 200
    Date: Wed, 14 Feb 2024 18:03:29 GMT
    Content-Type: application/json
    Transfer-Encoding: chunked
    Connection: keep-alive
    Content-Disposition: inline;filename=f.txt

    {"id":"mcoleiroj","name":"Walsh Group","email":"cgoodhallj@google.it"}
    ```

1. Create a customer

    ```shell
    curl -i -X POST 'http://<EXTERNAL-IP>/api/v2/customer' \
    -H 'Content-Type: application/json' \
    -d '{"id": "andyt", "name": "andytael", "email": "andy@andy.com"}'
    ```

    Returns:

    ```text
    -H 'Content-Type: application/json' \
    -d '{"id": "andyt", "name": "andytael", "email": "andy@andy.com"}'
    HTTP/1.1 201
    Date: Wed, 14 Feb 2024 19:18:13 GMT
    Content-Length: 0
    Connection: keep-alive
    Location: http://<EXTERNAL-IP>/api/v2/customer/andyt
    ```

1. Update a customer

    ```shell
    curl -i -X PUT "http://<EXTERNAL-IP>/api/v2/customer/wgeorgiev2r" \
    -H "Content-Type: application/json" \
    -d '{"id" : "wgeorgiev2r", "name" : "andytael", "email" : "andy@andy.com"}'
    ```

    Returns:

    ```text
    HTTP/1.1 200
    Date: Wed, 14 Feb 2024 19:49:39 GMT
    Content-Length: 0
    Connection: keep-alive
    ```

1. Delete a customer

    ```shell
    curl -i -X DELETE 'http://<EXTERNAL-IP>/api/v2/customer/andyt'
    ```

    Returns:

    ```text
    HTTP/1.1 200
    Date: Wed, 14 Feb 2024 19:28:38 GMT
    Content-Length: 0
    Connection: keep-alive
    ```
