$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sinatra'
require 'SlackBot'

require "nokogiri"
require "open-uri"

mention = "@matsubot"

$ERROR_CODE = -1
$PAGE_SIZE = 10000

$BOT_LAST_CHAR = ""

$FLAG_SHIRITORI = false
$FLAG_FIRST = false

help_message = "こんにちは．\nmatsubotです．\n
機能の説明をします．\n
1.「〇〇と言って」と言われると「〇〇」と返します．\n
2.しりとりを行うことができます．\n
しりとりの細かいルールを説明します．\n
(1)使用可能な文字はひらがな，カタカナ，漢字のみです\n
(2)「ー」は無視します   例：「ルビー」の最後の文字は「ビ」です\n
(3)拗音の小文字は大文字として扱います   例：「バッシュ」の最後の文字は「ユ」です\n\n
コマンドは以下の通りです．\n
help:このヘルプメッセージを表示\n
start:しりとりの開始\n
end:しりとりの終了\n
status:しりとり中かそうでないかを表示"

class MySlackBot < SlackBot
    #<string>と言ってをパース
    def parrot(str)
        idx_say = str.rindex("と言って")
        return str.slice(0..(idx_say - 1))
    end

    #Yahoo ルビ振り API
    def put_ruby_api(word)
        return "" if word.size >= 1000
        # p("@yapi:word = #{word}")
        enc_word = URI.encode(word)
        url = "http://jlp.yahooapis.jp/FuriganaService/V1/furigana?appid=#{@yahoo_api_key}&sentence=#{enc_word}"

        doc = Nokogiri::HTML(open(url)) rescue nil

        surface = doc.xpath('//word/surface').map{|i| i.text}.join rescue nil
        hiragana = doc.xpath('//word/furigana').map{|i| i.text}.join rescue nil
        roman = doc.xpath('//word/roman').map{|i| i.text}.join(' ') rescue nil

        return [ surface, hiragana, roman ]
    end

    #Wikipedia API
    def wiki_dict_api(word)
        enc_word = URI.encode(word)
        url = "http://public.dejizo.jp/NetDicV09.asmx/SearchDicItemLite?Dic=wpedia&Word=#{enc_word}&Scope=HEADWORD&Match=STARTWITH&Merge=AND&Prof=XHTML&PageSize=#{$PAGE_SIZE}&PageIndex=0"

        doc = Nokogiri::HTML(open(url)) rescue nil
        title = doc.xpath('///span[@class="NetDicTitle"]').map{|i| i.text} rescue nil
        return title

    end

    #和英辞典 API
    def e_dict_api(word)
        enc_word = URI.encode(word)
        url = "http://public.dejizo.jp/NetDicV09.asmx/SearchDicItemLite?Dic=EdictJE&Word=#{enc_word}&Scope=HEADWORD&Match=STARTWITH&Merge=AND&Prof=XHTML&PageSize=#{$PAGE_SIZE}&PageIndex=0"

        doc = Nokogiri::XML(open(url)) rescue nil
        id = doc.search("ItemID").map{|i| i.text} rescue nil
        title = doc.xpath('//span[@class="NetDicTitle"]').map{|i| i.text} rescue nil
        # p(id)
        # p(title)
        return id, title
    end

    #和英辞典の内容取得APIで品詞が名詞かを調べる
    def is_noun(dict_id)
        url = "http://public.dejizo.jp/NetDicV09.asmx/GetDicItemLite?Dic=EdictJE&Item=#{dict_id}&Loc=&Prof=XHTML"

        # p url
        doc = Nokogiri::XML(open(url)) rescue nil
        mean = doc.xpath('//div[@class="NetDicBody"]/div/div[1]').map{|i| i.text} rescue nil
        # p(mean)
        kind = mean[0][/\((.+?)\) /,1]
        # p(kind)
        if kind.match(/(^n(,(.+))*)$|(^((.+))*,n(,(.+))*$)|(^((.+))*,n$)/)
            return true
        else
            return false
        end
    end

    #IDの要素の単語と読みを返す
    def return_title_fromid(dict_id)
        url = "http://public.dejizo.jp/NetDicV09.asmx/GetDicItemLite?Dic=EdictJE&Item=#{dict_id}&Loc=&Prof=XHTML"

        # p url
        doc = Nokogiri::XML(open(url)) rescue nil
        title = doc.xpath('//span[@class="NetDicHeadTitle"]').map{|i| i.text}
        # return title[0][/［(.+)］/,1]
        return title[0].split(/\n\t*/)
    end

    #日本語のみかどうかを判定
    def valid_word(word)
        word_ruby =  put_ruby_api(word)
        word_ruby[0] = word_ruby[0].tr("０-９ａ-ｚＡ-Ｚ","0-9a-zA-Z")
        if word_ruby.include?(nil)
            post_message("使用できない文字が含まれています！", username: "matsubot")
            return $ERROR_CODE
        elsif word_ruby.include?(nil)
            if word_ruby[0] != nil
                if word_ruby[0].match(/\w/)
                    post_message("日本語のみで入力してください！", username: "matsubot")
                    return $ERROR_CODE
                else
                    post_message("その文字は認識不可能です！", username: "matsubot")
                    return $ERROR_CODE
                end
            else
                post_message("文字列が空の可能性があります！", username: "matsubot")
                return $ERROR_CODE
            end
        else
            if word_ruby[0].gsub(/\W/, "").length != 0
                post_message("日本語のみで入力してください！", username: "matsubot")
                return $ERROR_CODE
            else
                return word_ruby
            end
        end
    end

    #Wikipediaに記事があるかどうかで単語の存在を判定
    def exist_on_wiki(word)
        enc_word = URI.encode(word)
        url = "https://ja.wikipedia.org/wiki/#{enc_word}"
        doc = Nokogiri::HTML(open(url)) rescue nil
        if doc != nil
            return true
        else
            return false
        end
    end

    #「ん」で終わるかどうかを判定
    def valid_last_char(word)
        word_ruby = put_ruby_api(word)
        if word_ruby[1][-1] != "ん"
            return true
        else
            return false
        end
    end

    #最後の文字を返す
    def return_last_char(word)
        if word[-1] == "ー"
            return_last_char(word.chop!)
        end
        case word[-1]
        when "ぁ"
            return "あ"
        when "ぃ"
            return "い"
        when "ぅ"
            return "う"
        when "ぇ"
            return "え"
        when "ぉ"
            return "お"
        when "ゃ"
            return "や"
        when "ゅ"
            return "ゆ"
        when "ょ"
            return "よ"
        when "ゎ"
            return "わ"
        when "っ"
            return "つ"
        else
            return word[-1]
        end
    end

    #有効な言葉を探す
    def select_word(list)
        candidate = list.sample
        if valid_last_char(candidate)
            return candidate
        else
            select_word(list)
        end
    end

    #有効な言葉を探す(ID)
    def select_word_fromid(id_list)
        candidate_id = id_list.sample
        candidate_word = return_title_fromid(candidate_id)
        if candidate_word.length == 2
            candidate_word = candidate_word[1][/［(.+)］/,1]
            # p($BOT_LAST_CHAR)
        else
            candidate_word = candidate_word[0]
            # p($BOT_LAST_CHAR)
        end
        candidate_word = put_ruby_api(candidate_word)[1]
        # p(candidate_word)
        if valid_last_char(candidate_word)
            return candidate_id
        else
            select_word_fromid(id_list)
        end
    end

    def main(user_word)

        #適切な入力かどうか確認
        if valid_word(user_word) == $ERROR_CODE
            return
        end

        if $FLAG_FIRST
            $BOT_LAST_CHAR = put_ruby_api(user_word)[1][0]
            $FLAG_FIRST = false
        end

        if put_ruby_api(user_word)[1][0] != $BOT_LAST_CHAR
            post_message("\"#{$BOT_LAST_CHAR}\"から始めてください!", username: "matsubot")
            return
        end

        #Wikipediaに存在するか
        # if exist_on_wiki(user_word) == false
        #     puts("私の辞書には存在しない単語です")
        # end

        #入力をひらがなに変換
        user_word_ruby = put_ruby_api(user_word)

        #入力の最後の文字を取得
        user_last_char = return_last_char(user_word_ruby[1])

        #「ん」がついたら負け
        if valid_last_char(user_last_char) == false
            post_message("結果：あなたの負けです", username: "matsubot")
            $FLAG_SHIRITORI = false
            $FLAG_FIRST = false
            post_message("しりとりを終了します", username: "matsubot")
            $BOT_LAST_CHAR = ""
            return
        end
        # p(last_char)

        #入力の最後の文字から始まる単語を検索
        id_list, word_list = e_dict_api(user_last_char)

        #IDをランダムで選択し，単語を選択
        select_id = select_word_fromid(id_list)
        while is_noun(select_id) == false
            select_id = select_word_fromid(id_list)
        end
        res_word = return_title_fromid(select_id)

        #とりあえず出力
        if res_word.length == 2
            post_message("#{res_word[0]}(#{res_word[1][/［(.+)］/,1]})", username: "matsubot")
            $BOT_LAST_CHAR = return_last_char(res_word[1][/［(.+)］/,1])
            # p($BOT_LAST_CHAR)
        else
            post_message("#{res_word[0]}", username: "matsubot")
            $BOT_LAST_CHAR = return_last_char(put_ruby_api(res_word[0])[1])
            # p($BOT_LAST_CHAR)
        end
    end
end

def delete_space(str)
    if str[0] == " "
        str[0] = ""
        delete_space(str)
    end
    return str
end


set :environment, :production

slackbot = MySlackBot.new

get '/' do
  "SlackBot Server"
end

post '/slack' do
    content_type :json
    str = params[:text]
    if str.start_with?(mention)
        user_text = str.slice(mention.length..-1)
        user_text = delete_space(user_text)
        # slackbot.post_message(user_text.length.to_s, username: "matsubot")
        if str.include?("と言って")
            params[:text] = slackbot.parrot(user_text)
            slackbot.post_message(params[:text], username: "matsubot")
        else
            if user_text == "status"
                if $FLAG_SHIRITORI == true
                    if $BOT_LAST_CHAR == ""
                        slackbot.post_message("現在しりとりの途中です．最初のターンです．", username: "matsubot")
                    else
                        slackbot.post_message("現在しりとりの途中です．初めの文字は\"#{$BOT_LAST_CHAR}\"です．", username: "matsubot")
                    end
                else
                    slackbot.post_message("現在しりとりは行なっていません．", username: "matsubot")
                end
            elsif user_text == "help"
                slackbot.post_message(help_message, username: "matsubot")
            elsif ($FLAG_SHIRITORI == true) and (user_text == "end")
                $FLAG_SHIRITORI = false
                slackbot.post_message("しりとりを終了します", username: "matsubot")
                $BOT_LAST_CHAR = ""
            elsif $FLAG_SHIRITORI == true
                slackbot.main(user_text)
            elsif user_text == "start"
                $FLAG_SHIRITORI = true
                slackbot.post_message("しりとりを開始します．\n入力を行ってください．", username: "matsubot")
                $FLAG_FIRST = true
            else
                slackbot.post_message(help_message, username: "matsubot")
            end
        end
    end
end
