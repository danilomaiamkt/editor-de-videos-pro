// Mostra se cada arquivo do iCloud Drive já terminou de subir.
// Uso: swift icloud_status.swift <arquivo> [...]
// Saída por arquivo: "ENVIADO", "ENVIANDO 42%" ou "ERRO <motivo>".
import Foundation

for path in CommandLine.arguments.dropFirst() {
    let url = URL(fileURLWithPath: path)
    do {
        let v = try url.resourceValues(forKeys: [.ubiquitousItemIsUploadedKey, .ubiquitousItemIsUploadingKey, .ubiquitousItemUploadingErrorKey])
        if let erro = v.ubiquitousItemUploadingError {
            print("ERRO \(erro.localizedDescription)\t\(url.lastPathComponent)")
        } else if v.ubiquitousItemIsUploaded == true {
            print("ENVIADO\t\(url.lastPathComponent)")
        } else {
            var pct = ""
            if let q = NSMetadataQuery() as NSMetadataQuery? { _ = q }
            if let item = try? url.resourceValues(forKeys: [.ubiquitousItemIsUploadingKey]), item.ubiquitousItemIsUploading == true { pct = "ENVIANDO" } else { pct = "NA FILA" }
            print("\(pct)\t\(url.lastPathComponent)")
        }
    } catch {
        print("ERRO \(error.localizedDescription)\t\(url.lastPathComponent)")
    }
}
