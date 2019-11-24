# Ver 0.6.2

-fish start<br>
  釣りを開始する

-fish stop<br>
  釣りを停止する
  
-fish autoretry N<br>
  「ここで釣りはできません」エラー対策で指定回数だけリトライする

-fish autoring<br>
　エンチャントが切れたら自動で指輪を使用する。使用する指輪は設定可能<br>
  ```
  <AutoRingMode>
      <Ring>ペリカンリング</Ring>
      <Use>false</Use>
  </AutoRingMode>
  ```
　注：バフアイコンで判別できないので、２種類のリングを使い分けることは出来ない

-fish autofood<br>
　釣り人弁当が切れたらを自動で食べる<br>

-fish autostop N<br>
  「何も釣れなかった」が指定回数連続したら動作を停止する<br>

-fish cap N<br>
  釣りスキルが指定値になったら動作を停止する<br>
  WindowerのAPIで取得できるスキル値が不正確なため、若干の誤差がある<br>

-fish r<br>
  設定ファイルの再読み込み<br>
  リリース対象を編集したりした場合に使用<br>

-fish z 名前<br>
　ハラキリコマンド<br>
  Zaldonの近くで実行すると、カバンの中の対象魚を全てハラキリする<br>
  ※addonのtradeが必要<br>

# ToDo<br>
  [ ] 折れた竿の自動修理<br>
  [ ] 船の入港前のメッセージをテキストボックスに反映<br>
  
  
  
