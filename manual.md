# 1. install

우선 github에서 소스 코드를 가져옵니다.
``` bash
    git clone https://github.com/blockscout/blockscout.git
```

db는 postgresql, 언어는 elixir를 사용하는데, 이 둘을 전혀 몰라도 문제가 없었습니다.

## 1. Redis 설치
캐싱을 위해 Redis가 필요합니다.

``` bash
    sudo apt-get install redis-server
    sudo systemctl enable redis-server.service

    # 필요하다면
    sudo apt-get install libncurses5-dev
```

## 2. postgresql 설치, 셋업

``` bash
    # 설치
    sudo apt-get update
    sudo apt-get -y install postgresql
    sudo apt install postgresql-contrib

    # 실행
    sudo service postgresql start
    sudo -i -u postgres
    psql

    # psql 사용자 등록
    CREATE USER <user> WITH PASSWORD '<pw>';
    # e.g. CREATE USER lsj WITH PASSWORD '11';

    # blockscout을 위한 db 생성
    CREATE DATABASE <db name>
    # e.g. CREATE DATABASE blockscout

    # 권한 설정
    GRANT ALL PRIVILEGES ON DATABASE <db> TO <user>
    # e.g. GRANT ALL PRIVILEGES ON DATABASE blockscout TO lsj;

    # 이제 지정된 계정으로 해당 db를 조작할 수 있게 됩니다.
    psql -U <user> -d <db name>
    # e.g. psql -U lsj -d blockscout
```

cf) 만약 다음과 같은 에러가 난다면
``` bash
    msg : peer authentication failed for user "lsj"
```

이 경우 psql config 파일을 수정해주어야 합니다.
``` bash
    # 경로는 사용자마다 다를 가능성이 높습니다 (저는 루트 디렉토리(/)에 있었습니다.)
    sudo vim /etc/postgresql/16/main/pg_hba.conf

    # 해당 파일을 열어 local connection 항목을 peer에서 md5로 수정하고 postgresql을 재시작합니다.
    sudo service postgresql restart
```

## 3. dependencies 섪치
의존하는 프로그램이 많습니다. 전부 설치 해줍니다.

``` bash
    sudo apt-get install -y automake autoconf libtool build-essential libgmp3-dev erlang-dev erlang-tools make cmake curl screen

    # elixir, erlang 설치
    # install asdf
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.1

    # asdf 명령어를 .bashrc에 추가
    echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc

    # elixir 설치, 버전 설정
    asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
    sudo apt install unzip
    asdf install elixir 1.15.7
    asdf global elixir 1.15.7

    # erlang 설치
    asdf plugin-add erlang
    asdf install erlang 24.0 # version은 알아서 선택
    sudo apt install openssl libssl-dev openjdk-11-jdk unixodbc-dev libwxgtk3.0-gtk3-dev xsltproc fop libxml2-utils
    asdf global erlang 24.0 # global 대신 local을 쓰면 해당 프로젝트에서만 버전이 적용됨

    iex # 버전 확인
```

## 4. frontend 셋업
프론트는 js를 설치하는데, 빌드만 해주면 됩니다. (webpack)

디폴트 url은 `localhost:4000` 입니다.

``` bash
    cd apps/block_scout_web/assets
    npm i && node_modules/webpack/bin/webpack.js --mode production
```

## 5. 환경 변수 셋업
터미널에 몇 가지 환경 변수를 설정해야 합니다. 쉘 스크립트로 대체했습니다.

단, 이걸 실행하면 처음에는 에러가 뜹니다. 이는 https 통신을 위한 인증서가 없기 때문인데, 

지정된 장소에 스스로 생성한 인증서를 사용하면 됩니다.

``` bash
    #!/bin/bash

    export ETHEREUM_JSONRPC_VARIANT=geth
    export COIN=POA
    export NETWORK=POA
    export DATABASE_URL=postgresql://lsj:11@localhost:5432/blockscout # postgresql config 입력
    export ETHEREUM_JSONRPC_HTTP_URL=http://localhost:8545 # geth으 rpcurl 입력

    # db 초기화
    PGPASSWORD=11 dropdb -U lsj blockscout 
    PGPASSWORD=11 createdb -U lsj blockscout

    mix do deps.get, local.rebar --force, deps.compile, compile
    mix ecto.migrate


    mix phx.server
```

버전 차이가 있어 에러가 날 경우 asdf를 이용해 elixir, erlang을 최신 버전으로 설치합니다.
``` bash
    asdf install elixir 1.14.5-otp-25
    asdf install erlang 25.3.2.8
```

cf) swagger : `https://eth.blockscout.com/api-docs`

## 5. pem key 설정
위에서 `mix phx.server` 커맨드를 실행해 중간에 에러가 떳다면 다음 경로에서 pem 인증서를 생성할 수 있습니다.
아마 blockscout 프로젝트 루트 디렉토리에 _build 폴더가 생성되었을 겁니다. 거기에 다음과 같이 인증서를 생성하면 됩니다.
(직접 경로를 만들어야 합니다.)

``` bash
    # 인증서를 보관할 경로 생성 or 이동
    cd _build/dev/lib/block_scout_web/priv/cert

    # 인증서 생성
    openssl req -newkey rsa:2048 -nodes -keyout selfsigned_key.pem -x509 -days 365 -out selfsigned.pem
    # 이것 저것 설정하라고 할텐데 대충 입력해도 무방합니다.

    # 생성된 pem 파일의 접근 권한을 설정해줍니다.
    chmod 777 selfsigned_key.pem
    chmod 777 selfsigned.pem
```

이제 다시 쉘 스크립트 파일을 실행하면 이미 돌아가고 있는 geth에 연동되어 블록체인의 현황을 보여줍니다.