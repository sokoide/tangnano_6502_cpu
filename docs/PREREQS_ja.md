# 💻 必要なソフトウェア

- **GoWin EDA** (FPGA 合成・配置配線ツール)
- **Verilator** (SystemVerilog シミュレータ)
- **GTKWave** (波形表示ツール)
- **cc65** (6502 アセンブラ、Day 10 で使用)
- **srecord** (バイナリ変換ツール)
- **Make** (ビルドシステム)

## インストール手順

**macOS:**

- インストール

```bash
brew update
brew install srecord cc65 golang gtkwave verilator openssl@3
```

- すでに homebrew がインストールされている場合、Apple Silicon / Intel version を確認し、あなたの Mac の CPU とミスマッチがあったら homebrew を再インストールしてください

```bash
❯ brew --prefix
/opt/homebrew # this is Apple Silicon version (aarch64)
/usr/local # this is Intel version (x86_64)
```

**WSL/Linux (Ubuntu/Debian):**

```bash
sudo apt update
sudo apt install -y make srecord cc65 golang gtkwave verilator libnss3 libnspr4 libasound2-dev \
  libxcomposite1 libxcursor1 libxi6 libxtst6 libxrandr2 \
  libdbus-1-3 libfontconfig1 libxrender1 libxkbcommon0 libxext6 libx11-6 \
  libxdamage1 libxfixes3 libnss3 libnspr4 libgbm1
sudo apt install -y --reinstall \
  libfreetype6 \
  libfontconfig1
```

**GoWin EDA:**

- <https://www.gowinsemi.com/ja/support/download_eda/> から macOS, Windows, Linux 用の _Gowin V1.9.11.03 Education_ をダウンロードします
  - Mac ユーザーは、macOS 版 IDE のみが必要です(コンパイラとプログラマの両方が含まれています)
  - macOS 版 IDE は /Applications/GowinIDE.app にインストールしてください
  - Windows ユーザーは、Windows 上に Windows 版 IDE（コンパイラとプログラマ）、WSL 上に Linux 版 IDE（コンパイラ）をインストールする必要があります。WSL からはプログラマを使用できないため、WSL でコンパイルした場合でも Windows 版のプログラマが必要です
  - Linux 版 IDE は $(HOME)/Gowin/IDE にインストールしてください
  - Windows 版 IDE は c:\Gowin にインストールしてください
- macOS のみ
  - 初回 -> 開くのに失敗する場合
  - macOS の設定 -> プライバシーとセキュリティ -> 一番下までスクロール -> 実行を許可する
  - コマンドラインツールにパッチを当てる

```bash
GW=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE

for f in "$GW/bin/"*; do
  if file "$f" | grep -q executable; then
    install_name_tool \
      -add_rpath @executable_path/../lib \
      -add_rpath @executable_path/../Frameworks \
      "$f" 2>/dev/null
  fi
done

for f in "$GW/bin/"*; do
  if file "$f" | grep -q executable; then
    if otool -L "$f" | grep -q '/Library/Frameworks/Tcl.framework'; then
      install_name_tool \
        -change \
        /Library/Frameworks/Tcl.framework/Versions/8.6/Tcl \
        @rpath/Tcl.framework/Versions/8.6/Tcl \
        "$f"
    fi
  fi
done
```

- WSL only

```bash
# run this only once
# install IDE and programmer in $HOME/Gowin
# if you download `Gowin_V1.9.11.03_Education_Linux.tar.gz` in your Windows Downloads folder,
# it's visible at /mnt/c/Users/$Windows-User-ID/Downloads/Gowin_V1.9.11.03_Education_Linux.tar.gz
cd
mkdir Gowin
cd Gowin
tar axvf /mnt/c/Users/$Windows-User-ID/Downloads/Gowin_V1.9.11.03_Education_Linux.tar.gz

# run this only once
cd $HOME/Gowin/IDE/lib
mv libfreetype.so.6 libfreetype.so.6.gowin.bak

# run this every time when you open a shell
# set env var
export QT_QPA_PLATFORM=minimal
export QT_OPENGL=software
export QT_XCB_GL_INTEGRATION=none
```

## macOS のツールパスに関する注意

Gowin EDA をアプリとしてインストールしており、`gw_sh` や `programmer_cli` が `PATH` に通っていない場合、make 実行時にパスを指定可能です：

```bash
make GWSH=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh \
     PRG=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli \
     download
```
