import UIKit

class TasksListViewContoller: UIViewController {
    
    private enum Constants {
        static let gap: CGFloat = 16
        static let sizeOfAddButton: CGFloat = 54
        static let sizeOfRadioButton: CGSize = .init(width: 34, height: 34)
        static let filename = "Files"
        static let cellIndetifire = "Cell"
        static let cornerRaduis: CGFloat = 20
    }
    
    private let fileCache = FileCache(filename: Constants.filename)
    
    private var tasks: [TodoItem] {
        areCompletedTasksHidden ? fileCache.todoItems.filter { !$0.isCompleted } : fileCache.todoItems
    }
    
    private var numberOfCompletedTask: Int {
        fileCache.todoItems.reduce(into: 0) { partialResult, item in
            partialResult += item.isCompleted ? 1 : 0
        }
    }
    
    private var areCompletedTasksHidden = true
    
    private lazy var numberOfCompleteTaskLabel: UILabel = {
        let label = UILabel()
        label.text = "Выполнено - \(numberOfCompletedTask)"
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()
    
    private lazy var areHiddenCompletedTasksButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .background
        button.setTitle("Показать", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.blueApp, for: .normal)
        button.addTarget(self, action: #selector(hideOrShowCompletedTasks(_:)), for: .touchDown)
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIndetifire)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.tableFooterView = UIView()
        tableView.layer.cornerRadius = Constants.cornerRaduis
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
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var saveAlert: UIAlertController = {
        let alert = UIAlertController(title: "Ошибка сохранения", message: "Неудалось сохранить изменение. Возможно, у вас закончилась память", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "ОК", style: .cancel)
        alert.addAction(alertAction)
        return alert
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewSettings()
        setupViews()
        setupConstraint()
        fileCache.delegate = self
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
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        areCompletedTasksHidden.toggle()
        sender.setTitle(areCompletedTasksHidden ? "Показать" : "Скрыть", for: .normal)
        tableView.reloadData()
    }
    
    @objc private func addTask() {
        let taskController = TaskViewController()
        taskController.delegate = self
        let navContoller = UINavigationController(rootViewController: taskController)
        navContoller.modalPresentationStyle = .formSheet
        self.present(navContoller, animated: true)
    }
    
    @objc private func makeTaskIsCompleted(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView else {
            return
        }
        
        let item = tasks[imageView.tag]
        makeCompleted(item: item)
    }
}

// MARK: Первоначальный настройки
extension TasksListViewContoller {
    private func setupViewSettings() {
        view.backgroundColor = .background
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
        let yTableView = numberOfCompleteTaskLabel.frame.maxY + Constants.gap
        let xTableView: CGFloat = Constants.gap
        let widthTableView = view.bounds.width - Constants.gap * 2
        let height = tableView.contentSize.height
        tableView.frame = .init(x: xTableView, y: yTableView, width: widthTableView, height: height)
        addButton.frame = .init(x: view.bounds.width / 2 - Constants.sizeOfAddButton / 2, y: view.bounds.height - Constants.sizeOfAddButton * 2, width: Constants.sizeOfAddButton, height: Constants.sizeOfAddButton)
        scrollView.contentSize = .init(width: view.bounds.width,
                                       height: height + numberOfCompleteTaskLabel.bounds.height + view.safeAreaInsets.top)
    }
}

// MARK: TableViewDataSource
extension TasksListViewContoller: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == tableView.numberOfRows(inSection: 0) - 1 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: Constants.cellIndetifire)
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.text = "Новое"
            cell.imageView?.image = UIImage(systemName: "circle")?.resized(to: Constants.sizeOfRadioButton)
            cell.imageView?.isHidden = true
            return cell
        }
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Constants.cellIndetifire)
        let item = tasks[indexPath.row]
        let configurationForChevron = UIImage.SymbolConfiguration(paletteColors: [.lightGray])
        cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: configurationForChevron))
        cell.textLabel?.numberOfLines = 3
        cell.detailTextLabel?.textColor = .gray
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 15)
        if item.isCompleted {
            cell.textLabel?.attributedText = getStrikethroughText(string: item.text)
            cell.textLabel?.textColor = .lightGray
            let configuration = UIImage.SymbolConfiguration(paletteColors: [.greenApp])
            cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill",withConfiguration: configuration)?.resized(to: Constants.sizeOfRadioButton)
            return cell
        }
        
        var configurationForRadioButton = UIImage.SymbolConfiguration(paletteColors: [.lightGray])
        if let deadline = item.deadline {
            if deadline < Date.now {
                configurationForRadioButton = UIImage.SymbolConfiguration(paletteColors: [.redApp])
            } else {
                cell.detailTextLabel?.attributedText = getFormattedDeadlineString(deadline: deadline)
            }
        }
        cell.imageView?.image = UIImage(systemName: "circle",withConfiguration: configurationForRadioButton)?.resized(to: Constants.sizeOfRadioButton)
        cell.textLabel?.text = item.priority == .important ? "‼️\(item.text)" : item.text
        cell.imageView?.addGestureRecognizer(makeTapRecognizerForRadioButton())
        cell.imageView?.isUserInteractionEnabled = true
        cell.imageView?.tag = indexPath.row
        return cell
    }
    
    // MARK: Поддержка preview
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: { () -> UIViewController? in
                let item = self.tasks[indexPath.row]
                let taskViewController = TaskViewController()
                taskViewController.todoItem = item
                taskViewController.delegate = self
                return taskViewController
            }
        )
    }
    
    private func makeTapRecognizerForRadioButton() -> UITapGestureRecognizer {
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(makeTaskIsCompleted)
        )
        tapRecognizer.numberOfTouchesRequired = 1
        return tapRecognizer
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

// MARK: TableViewDelegate
extension TasksListViewContoller: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .backgroundGray
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let taskController = TaskViewController()
        taskController.delegate = self
        let navController = UINavigationController(rootViewController: taskController)
        navController.modalPresentationStyle = .formSheet
        if indexPath.row != tasks.count {
            taskController.todoItem = tasks[indexPath.row]
        }
        self.present(navController, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: Правый свайп ячейки
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < tasks.count else { return nil }
        let item = tasks[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: nil) {_,_,_ in
            self.delete(item: item)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .redApp
        
        let getInfoAction = UIContextualAction(style: .normal, title: nil) { _, _, _ in
            let taskViewController = TaskViewController()
            let navController = UINavigationController(rootViewController: taskViewController)
            taskViewController.todoItem = item
            taskViewController.delegate = self
            navController.modalPresentationStyle = .formSheet
            self.present(navController, animated: true)
        }
        getInfoAction.image = UIImage(systemName: "info.circle.fill")
        getInfoAction.backgroundColor = .lightGray
        
        return UISwipeActionsConfiguration(actions: [deleteAction,getInfoAction])
    }
    // MARK: Левый свайп ячейки
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < tasks.count else { return nil }
        let item = tasks[indexPath.row]
        let makeTaskCompleted = UIContextualAction(style: .normal, title: nil) { _, _, _ in
            self.makeCompleted(item: item)
        }
        
        makeTaskCompleted.backgroundColor = .greenApp
        makeTaskCompleted.image = UIImage(systemName: "checkmark.circle.fill")
        
        return UISwipeActionsConfiguration(actions: [makeTaskCompleted])
    }
    
    // MARK: Поддержка preview
    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let taskViewController = animator.previewViewController as? TaskViewController else {
            return
        }
        let navController = UINavigationController(rootViewController: taskViewController)
        
        animator.addAnimations {
            self.present(navController, animated: true)
        }
    }
}

// MARK: Изменение размерка картинки
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: TasksListViewControllerDelegate

protocol TasksListViewContollerDelegate: AnyObject {
    func update(item: TodoItem)
    func delete(item: TodoItem)
    func makeCompleted(item: TodoItem)
}

extension TasksListViewContoller: TasksListViewContollerDelegate {
    func update(item: TodoItem) {
        fileCache.addNew(task: item)
        do {
            try fileCache.saveAllItems(to: Constants.filename)
        } catch {
            self.present(saveAlert, animated: true)
        }
    }
    
    func delete(item: TodoItem) {
        fileCache.remove(task: item)
        do {
            try fileCache.saveAllItems(to: Constants.filename)
        } catch {
            self.present(saveAlert, animated: true)
        }
    }
    
    func makeCompleted(item: TodoItem) {
        let newItem = item.makeCompleted()
        self.fileCache.addNew(task: newItem)
        do {
            try self.fileCache.saveAllItems(to: Constants.filename)
        } catch {
            self.present(saveAlert, animated: true)
        }
    }
}

// MARK: FileCacheDelegate
extension TasksListViewContoller: FileCacheDelegate {
    func updateItems() {
        self.numberOfCompleteTaskLabel.text = "Выполнено - \(self.numberOfCompletedTask)"
        self.tableView.reloadData()
        DispatchQueue.main.async {
            self.view.setNeedsLayout()
        }
    }
}

// MARK: Цветовая палитра
extension UIColor {
    static let background = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        default:
            return UIColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1.0)
        }
    }
    
    static let backgroundGray = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
        default:
            return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        }
    }
    
    static let blueApp = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0)
        default:
            return UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        }
    }
    
    static let greenApp = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 0.2, green: 0.84, blue: 0.29, alpha: 1.0)
        default:
            return UIColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0)
        }
    }
    
    static let redApp = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0)
        default:
            return UIColor(red: 1.0, green: 0.23, blue: 0.19, alpha: 1.0)
        }
    }
}
