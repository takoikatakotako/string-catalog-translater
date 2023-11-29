import Foundation
import ClientRuntime
import AWSTranslate

await main()

func main() async {
    let sourceFilePath = "en.lproj/Localizable.strings"
    
    do {
        let sourceLines = try String(contentsOf: URL(filePath: sourceFilePath), encoding: .utf8)
            .split(whereSeparator: \.isNewline)

        let laungages = ["af", "sq", "am", "ar", "hy", "az", "bn", "bs", "bg", "ca", "zh", "zh-TW", "hr", "cs", "da", "fa-AF", "nl", "et", "fa", "tl", "fi", "fr", "fr-CA", "ka", "de", "el", "gu", "ht", "he", "hi", "hu", "is", "id", "ga", "it", "kn", "kk", "ko", "lv", "lt", "mk", "ms", "ml", "mt", "", "mr", "mn", "no", "ps", "pl", "pt", "pt-PT", "pa", "ro", "ru", "sr", "si", "sk", "sl", "so", "es", "es-MX", "sw", "sv", "ta", "te", "th", "tr", "uk", "ur", "uz", "vi", "cy"]

        for laungage in laungages {
            var translatedText = ""
            for sourceLine in sourceLines {
                guard let result = parse(line: String(sourceLine)) else {
                    // パースできない場合はそのまま出力
                    translatedText += sourceLine + "\n"
                    continue
                }
                let key = result.key
                let value = result.value
                
                // 翻訳
                let translatedValue = try await translate(sourceLanguageCode: "en", targetLanguageCode: laungage, text: value) ?? value
                translatedText += "\"\(key)\" = \"\(translatedValue)\";\n"
            }
            
            // 出力
            let destinationDirectoryPath = "output/\(laungage).lproj/"
            try export(text: translatedText, destinationDirectoryPath: destinationDirectoryPath)
        }
    } catch {
        print(error)
    }
}

func parse(line: String) -> (key: String, value: String)? {
    let list = line.components(separatedBy: "\" = \"")
    guard list.count == 2 else {
        return nil
    }
    
    var key = list[0]
    guard key.prefix(1) == "\"" else {
        return nil
    }
    key = String(key.suffix(key.count - 1))
    
    var value = list[1]
    guard value.suffix(2) == "\";" else {
        return nil
    }
    value = String(value.prefix(value.count - 2))

    return (key, value)
}

func translate(sourceLanguageCode: String, targetLanguageCode: String, text: String) async throws -> String? {
    let client = try await TranslateClient()
    let input = TranslateTextInput(sourceLanguageCode: sourceLanguageCode, targetLanguageCode: targetLanguageCode, text: text)
    let output = try await client.translateText(input: input)
    return output.translatedText
}

func export(text: String, destinationDirectoryPath: String) throws {
    try FileManager.default.createDirectory(atPath: destinationDirectoryPath, withIntermediateDirectories: true, attributes: nil)
    let destinationFilePath = destinationDirectoryPath + "Localizable.strings"
    let data = Data(text.utf8)
    try data.write(to: URL(filePath: destinationFilePath))
}
