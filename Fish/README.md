#Ver 0.6.2

fish start
  釣りを開始する

fish stop
  釣りを停止する
  
fish autoretry N
  「ここで釣りはできません」エラー対策で指定回数だけリトライする

fish autoring
　エンチャントが切れたら自動で指輪を使用する。使用する指輪は設定可能
  <AutoRingMode>
      <Ring>ペリカンリング</Ring>
      <Use>false</Use>
  </AutoRingMode>
　注：バフアイコンで判別できないので、２種類のリングを使い分けることは出来ない

fish autofood
　釣り人弁当が切れたらを自動で食べる

fish autostop N
  「何も釣れなかった」が指定回数連続したら動作を停止する

fish cap N
  釣りスキルが指定値になったら動作を停止する
  WindowerのAPIで取得できるスキル値が不正確なため、若干の誤差がある

fish r
  設定ファイルの再読み込み
  リリース対象を編集したりした場合に、使用

fish z 名前
　ハラキリコマンド
  Zaldonの近くで実行すると、カバンの中の対象魚を全てハラキリする
  ※addonのtradeが必要

ToDo
  ・折れた竿の自動修理
  ・船の入港前のメッセージをテキストボックスに反映
  ・ネタ募集中(実現できる保証はありません)
  
  
  