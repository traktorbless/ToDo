import UIKit
import CocoaLumberjack

class TasksListViewContoller: UIViewController {
    private enum Constants {
        static let gap: CGFloat = 16
        static let sizeOfAddButton: CGFloat = 54
        static let sizeOfRadioButton: CGSize = .init(width: 34, height: 34)
        static let filename = "Items"
        static let cellIndetifire = "Cell"
        static let cornerRaduis: CGFloat = 20
        static let numberOfLinesInCell = 3
        static let sizeOfFooterTableViewItem: CGFloat = 20
        static let widthOfLabelNumberOfCompledTasks: CGFloat = 140
        static let widthOfButtonHidingTasks: CGFloat = 70
        static let standartSizeOfFont: CGFloat = 17
    }

    private let toDoItemService = ToDoItemsService(filename: Constants.filename)

    private lazy var tableViewHeightConstraint: NSLayoutConstraint = tableView.heightAnchor.constraint(equalToConstant: tableView.contentSize.height)

    private var viewTasks: [TodoItem] = []

    private var numberOfCompletedTask: Int {
        toDoItemService.todoItems.reduce(into: 0) { partialResult, item in
            partialResult += item.isCompleted ? 1 : 0
        }
    }

    private var isCompletedTasksHidden = true

    private lazy var numberOfCompleteTaskLabel: UILabel = {
        let label = UILabel()
        label.text = "Выполнено - \(numberOfCompletedTask)"
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: Constants.standartSizeOfFont)
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
        tableView.isScrollEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
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

    private lazy var loadAlert: UIAlertController = {
        let alert = UIAlertController(title: "Ошибка загрузки", message: "Неудалось загрузить данные", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "ОК", style: .cancel)
        alert.addAction(alertAction)
        return alert
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadItems()
        setupViewSettings()
        setupViews()
        setupConstraint()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupFrames()
        DispatchQueue.main.async {
            self.view.setNeedsLayout()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupFrames()
    }
}

// MARK: Constraints
extension TasksListViewContoller {
    private func setupConstraint() {
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            numberOfCompleteTaskLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Constants.gap*2),
            numberOfCompleteTaskLabel.widthAnchor.constraint(equalToConstant: Constants.widthOfLabelNumberOfCompledTasks),
            numberOfCompleteTaskLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Constants.gap),
            numberOfCompleteTaskLabel.heightAnchor.constraint(equalToConstant: Constants.sizeOfFooterTableViewItem)
        ])

        NSLayoutConstraint.activate([
            areHiddenCompletedTasksButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Constants.gap*2 - view.safeAreaInsets.right),
            areHiddenCompletedTasksButton.widthAnchor.constraint(equalToConstant: Constants.widthOfButtonHidingTasks),
            areHiddenCompletedTasksButton.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: Constants.gap),
            areHiddenCompletedTasksButton.heightAnchor.constraint(equalToConstant: Constants.sizeOfFooterTableViewItem)
        ])

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: numberOfCompleteTaskLabel.bottomAnchor, constant: 10),
            tableViewHeightConstraint
        ])

    }
}

// MARK: Targets
extension TasksListViewContoller {
    @objc private func hideOrShowCompletedTasks(_ sender: UIButton) {
        isCompletedTasksHidden.toggle()
        viewTasks = isCompletedTasksHidden ? toDoItemService.todoItems.filter { !$0.isCompleted } : toDoItemService.todoItems
        sender.setTitle(isCompletedTasksHidden ? "Показать" : "Скрыть", for: .normal)
        tableView.reloadData()
    }

    @objc private func addTask() {
        let taskController = TaskViewController()
        taskController.delegate = self
        let navContoller = UINavigationController(rootViewController: taskController)
        navContoller.modalPresentationStyle = .formSheet
        self.present(navContoller, animated: true)
    }

    @objc private func recongizerAction(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView else {
            return
        }

        let item = viewTasks[imageView.tag]
        if isCompletedTasksHidden {
            viewTasks.remove(at: imageView.tag)
            tableView.deleteRows(at: [IndexPath(row: imageView.tag, section: 0)], with: .fade)
        }
        makeCompleted(item: item)
    }
}

// MARK: Первоначальный настройки
extension TasksListViewContoller {
    private func loadItems() {
        toDoItemService.load { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.viewTasks = self.isCompletedTasksHidden ? self.toDoItemService.todoItems.filter { !$0.isCompleted } : self.toDoItemService.todoItems
                DDLogInfo("Загрузка прошла успешно")
            case .failure(let error):
                DDLogWarn("Во время загрузки произошла ошибка: \(error)")
            }
            self.save()
        }
    }

    private func setupViewSettings() {
        view.backgroundColor = .background
        toDoItemService.delegate = self
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
        tableView.invalidateIntrinsicContentSize()
        tableView.layoutIfNeeded()
        let height = tableView.contentSize.height
        addButton.frame = .init(x: view.bounds.width / 2 - Constants.sizeOfAddButton / 2,
                                y: view.bounds.height - Constants.sizeOfAddButton * 2,
                                width: Constants.sizeOfAddButton,
                                height: Constants.sizeOfAddButton)
        scrollView.contentSize = .init(width: view.bounds.width,
                                       height: height + numberOfCompleteTaskLabel.bounds.height + view.safeAreaInsets.bottom)
        tableViewHeightConstraint.constant = height
    }
}

// MARK: TableViewDataSource
extension TasksListViewContoller: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewTasks.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == viewTasks.count {
            let cell = UITableViewCell(style: .default, reuseIdentifier: Constants.cellIndetifire)
            cell.textLabel?.textColor = .lightGray
            cell.textLabel?.text = "Новое"
            cell.imageView?.image = UIImage(systemName: "circle")?.resized(to: Constants.sizeOfRadioButton)
            cell.imageView?.isHidden = true
            return cell
        }
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Constants.cellIndetifire)
        let item = viewTasks[indexPath.row]
        let configurationForChevron = UIImage.SymbolConfiguration(paletteColors: [.lightGray])
        cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: configurationForChevron))
        cell.textLabel?.numberOfLines = Constants.numberOfLinesInCell
        cell.detailTextLabel?.textColor = .gray
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 15)
        if item.isCompleted {
            cell.textLabel?.attributedText = getStrikethroughText(string: item.text)
            cell.textLabel?.textColor = .lightGray
            let configuration = UIImage.SymbolConfiguration(paletteColors: [.greenApp])
            cell.imageView?.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: configuration)?.resized(to: Constants.sizeOfRadioButton)
            cell.imageView?.addGestureRecognizer(makeTapRecognizerForRadioButton())
            cell.imageView?.isUserInteractionEnabled = true
            cell.imageView?.tag = indexPath.row
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
        cell.imageView?.image = UIImage(systemName: "circle", withConfiguration: configurationForRadioButton)?.resized(to: Constants.sizeOfRadioButton)
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
            previewProvider: { [weak self] () -> UIViewController? in
                let item = self?.viewTasks[indexPath.row]
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
            action: #selector(recongizerAction)
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
        if indexPath.row != viewTasks.count {
            taskController.todoItem = viewTasks[indexPath.row]
        }
        self.present(navController, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: Правый свайп ячейки
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < viewTasks.count else { return nil }
        let item = viewTasks[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: nil) {[unowned self] _, _, _ in
            self.viewTasks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.delete(item: item)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .redApp

        let getInfoAction = UIContextualAction(style: .normal, title: nil) {[unowned self]  _, _, _ in
            let taskViewController = TaskViewController()
            let navController = UINavigationController(rootViewController: taskViewController)
            taskViewController.todoItem = item
            taskViewController.delegate = self
            navController.modalPresentationStyle = .formSheet
            self.present(navController, animated: true)
        }
        getInfoAction.image = UIImage(systemName: "info.circle.fill")
        getInfoAction.backgroundColor = .lightGray

        return UISwipeActionsConfiguration(actions: [deleteAction, getInfoAction])
    }
    // MARK: Левый свайп ячейки
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < viewTasks.count else { return nil }
        let item = viewTasks[indexPath.row]
        let makeTaskCompleted = UIContextualAction(style: .normal, title: nil) {[unowned self] _, _, _ in
            if self.isCompletedTasksHidden {
                self.viewTasks.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
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

// MARK: TasksListViewControllerDelegate
protocol TasksListViewContollerDelegate: AnyObject {
    func update(item: TodoItem)
    func delete(item: TodoItem)
    func makeCompleted(item: TodoItem)
    func add(item: TodoItem)
}

extension TasksListViewContoller: TasksListViewContollerDelegate {
    private func save() {
        self.toDoItemService.save { result in
            switch result {
            case .success:
                DDLogInfo("Локально сохранение прошло успешно")
            case .failure(let error):
                DDLogWarn("При локальной сохранении произошла ошибка: \(error)")
            }
        }
    }
    func update(item: TodoItem) {
        toDoItemService.editItem(item: item) { [weak self] result in
            switch result {
            case .success(let changedItem):
                DDLogInfo("Задача с ID: \(changedItem.id) была изменена")
            case .failure(let error):
                DDLogWarn("При попытке изменить задачу с ID: \(item.id) произошла ошибка: \(error)")
            }
            self?.save()
        }
    }

    func add(item: TodoItem) {
        toDoItemService.addNew(item: item) { [weak self] result in
            switch result {
            case .success(let addedItem):
                DDLogInfo("Задача с ID: \(addedItem.id) была добавлена")
            case .failure(let error):
                DDLogWarn("При попытке добавить задачу с ID: \(item.id) произошла ошибка: \(error)")
            }
            self?.save()
        }
    }

    func delete(item: TodoItem) {
        toDoItemService.remove(item: item) { [weak self] result in
            switch result {
            case .success(let deletedID):
                DDLogInfo("Задача с ID: \(deletedID.id) была удалена")
            case .failure(let error):
                DDLogWarn("При попытке удалить задачу с ID:\(item.id) произошла ошибка :\(error)")
            }
            self?.save()
        }
    }

    func makeCompleted(item: TodoItem) {
        let newItem = item.asCompleted
        toDoItemService.editItem(item: newItem) { [weak self] result in
            switch result {
            case .success(let completedItem):
                DDLogInfo("Задача с ID: \(completedItem.id) была помечена как выполенная")
            case .failure(let error):
                DDLogWarn("При попытке пометить выполенной задачу с ID:\(item.id) произошла ошибка :\(error)")
            }
            self?.save()
        }
    }
}

 // MARK: ToDoItemsServiceProtocol
 extension TasksListViewContoller: ToDoItemsServiceDelegate {
    func updateView() {
        assert(Thread.isMainThread)
        viewTasks = isCompletedTasksHidden ? toDoItemService.todoItems.filter { !$0.isCompleted } : toDoItemService.todoItems
        self.numberOfCompleteTaskLabel.text = "Выполнено - \(self.numberOfCompletedTask)"
        self.tableView.reloadData()
        self.tableView.layoutIfNeeded()
        DispatchQueue.main.async { [weak self] in
            self?.view.setNeedsLayout()
        }
    }
 }
