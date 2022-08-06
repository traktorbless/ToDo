import UIKit

class TasksListViewContoller: UIViewController {
    
    private enum Constants {
        static let gap: CGFloat = 16
        static let sizeOfAddButton: CGFloat = 54
        static let sizeOfRadioButton: CGSize = .init(width: 34, height: 34)
    }
    
    private let items: [TodoItem] = [TodoItem(text: "Купить хлеб"), TodoItem(text: "Школа"),TodoItem(text: "ДЗ2",priority: .important,deadline: Date.now + 3600), TodoItem(text: "Молоко",isCompleted: true)]
    
    private let fileCache = FileCache(filename: "Files")
    
    private let cellIndetifire = "Cell"
    
    private lazy var numberOfCompleteTaskLabel: UILabel = {
        let label = UILabel()
        label.text = "Выполнено - 5"
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()
    
    private lazy var areHiddenCompletedTasksButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .backgroundLight
        button.setTitle("Показать", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.blueForButtonLight, for: .normal)
        button.addTarget(self, action: #selector(hideOrShowCompletedTasks(_:)), for: .touchDown)
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIndetifire)
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.tableFooterView = UIView()
        tableView.layer.cornerRadius = 20
        return tableView
    }()
    
    private lazy var addButton: UIImageView = {
        let image = UIImage(systemName: "plus.circle.fill")
        let imageView = UIImageView(image: image)
        imageView.layer.shadowRadius = 2
        imageView.layer.shadowOffset = .init(width: 0, height: 2)
        imageView.layer.shadowOpacity = 0.4
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = Constants.sizeOfAddButton
        imageView.addGestureRecognizer(addTaskTapRecognizer)
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private lazy var addTaskTapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(addTask)
        )
        tapRecognizer.numberOfTapsRequired = 1
        return tapRecognizer
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var makeTaskIsCompletedGesture: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(makeTaskIsCompleted)
        )
        tapRecognizer.numberOfTouchesRequired = 1
        return tapRecognizer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewSettings()
        setupViews()
        setupConstraint()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupFrames()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupFrames()
    }
    
    private func setupConstraint() {
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            numberOfCompleteTaskLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            numberOfCompleteTaskLabel.widthAnchor.constraint(equalToConstant: 140),
            numberOfCompleteTaskLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            numberOfCompleteTaskLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        NSLayoutConstraint.activate([
            areHiddenCompletedTasksButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32 - view.safeAreaInsets.right),
            areHiddenCompletedTasksButton.widthAnchor.constraint(equalToConstant: 70),
            areHiddenCompletedTasksButton.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            areHiddenCompletedTasksButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
}

// MARK: Targets
extension TasksListViewContoller {
    @objc private func hideOrShowCompletedTasks(_ sender: UIButton) {
    }
    
    @objc private func addTask() {
        print("AddTask")
    }
    
    @objc private func makeTaskIsCompleted() {
        print("Tap")
    }
}

// MARK: Первоначальный настройки
extension TasksListViewContoller {
    private func setupViewSettings() {
        view.backgroundColor = .backgroundLight
        title = "Мои дела"
    }
    
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(numberOfCompleteTaskLabel)
        scrollView.addSubview(areHiddenCompletedTasksButton)
        scrollView.addSubview(tableView)
        view.addSubview(addButton)
    }
    
    private func setupFrames() {
        let yTableView = numberOfCompleteTaskLabel.frame.maxY + 16
        let xTableView: CGFloat = 16
        let widthTableView = view.bounds.width - 32
        let height = tableView.contentSize.height
        tableView.frame = .init(x: xTableView, y: yTableView, width: widthTableView, height: height)
        addButton.frame = .init(x: view.bounds.width / 2 - Constants.sizeOfAddButton / 2, y: view.bounds.height - Constants.sizeOfAddButton * 2, width: Constants.sizeOfAddButton, height: Constants.sizeOfAddButton)
        scrollView.contentSize = .init(width: view.bounds.width,
                                       height: tableView.bounds.height + numberOfCompleteTaskLabel.bounds.height + 32)
    }
}

// MARK: TableView
extension TasksListViewContoller: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == items.count {
            let cell = UITableViewCell(style: .default, reuseIdentifier: cellIndetifire)
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.text = "Новое"
            let configuration = UIImage.SymbolConfiguration(paletteColors: [.white])
            cell.imageView?.image = UIImage(systemName: "circle",withConfiguration: configuration)?.resized(to: Constants.sizeOfRadioButton)
            return cell
        }
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIndetifire)
        let item = items[indexPath.row]
        let configurationForChevron = UIImage.SymbolConfiguration(paletteColors: [.lightGray])
        cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: configurationForChevron))
        cell.textLabel?.numberOfLines = 3
        cell.detailTextLabel?.textColor = .gray
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 15)
        if item.isCompleted {
            cell.textLabel?.attributedText = getStrikethroughText(string: item.text)
            cell.textLabel?.textColor = .lightGray
            let configuration = UIImage.SymbolConfiguration(paletteColors: [.lightGreen])
            cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill",withConfiguration: configuration)?.resized(to: Constants.sizeOfRadioButton)
            return cell
        }
        
        var configurationForRadioButton = UIImage.SymbolConfiguration(paletteColors: [.lightGray])
        if let deadline = item.deadline {
            if deadline < Date.now {
                configurationForRadioButton = UIImage.SymbolConfiguration(paletteColors: [.lightRed])
            } else {
                cell.detailTextLabel?.attributedText = getFormattedDeadlineString(deadline: deadline)
            }
        }
        cell.imageView?.image = UIImage(systemName: "circle",withConfiguration: configurationForRadioButton)?.resized(to: Constants.sizeOfRadioButton)
        cell.textLabel?.text = item.priority == .important ? "‼️\(item.text)" : item.text
        cell.imageView?.addGestureRecognizer(makeTaskIsCompletedGesture)
        cell.imageView?.isUserInteractionEnabled = true
        return cell
    }
    
    private func getFormattedDeadlineString(deadline: Date) -> NSMutableAttributedString {
        let attachment = NSTextAttachment()
        let configurationForImage = UIImage.SymbolConfiguration(paletteColors: [.lightGray])
        attachment.image = UIImage(systemName: "calendar", withConfiguration: configurationForImage)
        let imageString = NSMutableAttributedString(attachment: attachment)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d LLLL"
        let date = dateFormatter.string(from: deadline)
        let textString = NSAttributedString(string: date)
        imageString.append(textString)
        
        return imageString
    }
    
    private func getStrikethroughText(string: String) -> NSAttributedString {
         NSAttributedString(
            string: string,
            attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
        )
    }
}

extension TasksListViewContoller: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == items.count {
            tableView.deselectRow(at: indexPath, animated: false)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: Цветовая палитра
extension UIColor {
    static let backgroundLight = UIColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1.0)
    static let blueForButtonLight = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
    static let lightGreen = UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0)
    static let lightRed = UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
}

// MARK: Изменение размерка картинки
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
