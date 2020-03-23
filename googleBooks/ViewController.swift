import UIKit

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bookCell", for: indexPath)
        cell.textLabel?.text = bookList[indexPath.row].title
        
        if let imageData = try? Data(contentsOf: bookList[indexPath.row].image){
            cell.imageView?.image = UIImage(data: imageData)
        }
        return cell
    }
    

    @IBOutlet weak var searchText: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var bookList : [(title:String, authors:[String], image:URL)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchText.delegate = self
        searchText.placeholder = "本の名前を入力してください。"
        
        tableView.dataSource = self
    }
    
//    searchbar検索ボタンタップで呼ばれる
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        キーボードを閉じる
        view.endEditing(true)
        if let searchWord = searchBar.text {
//            print(searchWord)
              searchBooks(keyword: searchWord)
        }
    }
    
//    本の個別情報 struct=構造体。複数のデータを管理。
    // imageLinkのデータ構造
    struct  ImageLinkJson: Codable {
        let smallThumbnail: URL?
    }
    // JSONのItem内のデータ構造
    struct VolumeInfoJson: Codable {
        // 本の名称
        let title: String?
        // 著者
        let authors: [String]?
        // 本の画像
        let imageLinks: ImageLinkJson?
    }
    // Jsonのitem内のデータ構造
    struct ItemJson: Codable {
        let volumeInfo: VolumeInfoJson?
    }

    // JSONのデータ構造
    struct ResultJson: Codable {
        // 複数要素
//        let kind: String?
//        let totalItems: Int?
        let items: [ItemJson]?
    }

    // 第一引数：keyword 検索したいワード
    func searchBooks(keyword : String) {
        // 本のISBN情報をURLエンコードする
        guard let keyword_encode = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }

        // リクエストURLの組み立て
        guard let req_url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(keyword_encode)") else {
            return
        }
        print(req_url)

        // リクエストに必要な情報を生成
        let req = URLRequest(url: req_url)
        // データ転送を管理するためのセッションを生成
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        // リクエストをタスクとして登録
        let task = session.dataTask(with: req, completionHandler: {
            (data , response , error) in
            // セッションを終了
            session.finishTasksAndInvalidate()
            // do try catch エラーハンドリング
            do {
                //JSONDecoderのインスタンス取得
                let decoder = JSONDecoder()
                // 受け取ったJSONデータをパース(解析)して格納
                let json = try decoder.decode(ResultJson.self, from: data!)
//                print(json)
                
                if let items = json.items{
                    self.bookList.removeAll()
                    for item in items {
                        if let title = item.volumeInfo?.title, let author = item.volumeInfo?.authors, let image = item.volumeInfo?.imageLinks?.smallThumbnail {
                            let book = (title, author, image)
                            self.bookList.append(book)
                        }
                    }
                    
                    self.tableView.reloadData()
                    if let bookdbg = self.bookList.first {
                        print("----------")
                        print("bookList[0] = \(bookdbg)")
                    }
                }

            } catch {
                // エラー処理
                print("エラー？")
                print(error)
            }
        })
        // ダウンロード開始
        task.resume()
    }

    


}

