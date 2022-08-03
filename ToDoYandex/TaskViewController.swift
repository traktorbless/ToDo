import UIKit

class TaskViewController: UIViewController {
    
    private enum Constants {
        static let sizeOfDatePickerCell: CGFloat = 295
        static let sizeOfCell: CGFloat = 60
        static let cornerRadius: CGFloat = 20
    }
    
    private var deadline: Date?
    
    private let filename = "Tasks"
    
    private let cellIdentifier = "Cell"
    
    private lazy var fileCache = FileCache(filename: filename)
    
    private lazy var todoItem: TodoItem? = FileCache(filename: filename).todoItems.last
    
    private lazy var constraintHideDatePicker = tableView.heightAnchor.constraint(equalToConstant: Constants.sizeOfCell * 2 - 5)
    private lazy var constraintShowDatePicker = tableView.heightAnchor.constraint(equalToConstant: Constants.sizeOfCell * 2 - 5 + Constants.sizeOfDatePickerCell)
    private lazy var constraintForScrollView = scrollView.heightAnchor.constraint(equalToConstant: view.bounds.height - 16)
    private var constraintForKeyboard: NSLayoutConstraint?
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        if todoItem?.text == "" {
            textView.text = "Что надо сделать?"
            textView.textColor = UIColor.lightGray
        }
        textView.isScrollEnabled = false
        textView.contentInset = UIEdgeInsets(top: 17, left: 16, bottom: 0, right: 16)
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.textColor = .label
        if UITraitCollection.current.userInterfaceStyle == .dark {
            textView.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
        }
        textView.sizeToFit()
        textView.layer.borderWidth = 0
        textView.layer.cornerRadius = Constants.cornerRadius
        textView.delegate = self
        return textView
    }()
    
    private lazy var deleteButtonView: UIButton = {
        let button = UIButton(type: .system)
        if UITraitCollection.current.userInterfaceStyle == .dark {
            button.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = Constants.cornerRadius
        button.backgroundColor = .white
        button.addTarget(self, action: #selector(deleteTask), for: .touchDown)
        button.setTitle("Удалить", for: .normal)
        button.setTitleColor(.red, for: .normal)
        return button
    }()
    
    private lazy var deadlineSwitch: UISwitch = {
        let mySwitch = UISwitch()
        mySwitch.addTarget(self, action: #selector(addDeadline(_:)), for: .valueChanged)
        return mySwitch
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        tableView.layer.cornerRadius = Constants.cornerRadius
        tableView.tableFooterView = UIView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isScrollEnabled = false
        return tableView
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.insetsLayoutMarginsFromSafeArea = true
        return scroll
    }()
    
    private lazy var segmentControl: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["↓","нет","‼️"])
        segment.frame.size = .init(width: 150, height: 36)
        return segment
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupColors()
        setupToDoItem()
        setupNavigationBar()
        setupView()
        tableView.delegate = self
        tableView.dataSource = self
        setupConstraints()
        registerForKeyboardNotifications()
    }
    
    override func viewDidLayoutSubviews() {
        scrollView.contentSize = .init(width: view.bounds.width, height: deleteButtonView.bounds.height + tableView.bounds.height + textView.bounds.height + 100)
    }
}

// MARK: Первоначальные настройки
extension TaskViewController {
    private func setupColors() {
        if UITraitCollection.current.userInterfaceStyle == .dark {
            view.backgroundColor = UIColor(red: 0.09, green: 0.09, blue: 0.09, alpha: 1.0)
            textView.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
            deleteButtonView.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
            tableView.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
            deleteButtonView.setTitleColor(UIColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0), for: .normal)
        } else {
            view.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.95, alpha: 1.0)
        }
    }
    
    private func setupView() {
        view.addSubview(scrollView)
        scrollView.addSubview(textView)
        scrollView.addSubview(tableView)
        scrollView.addSubview(deleteButtonView)
    }
    
    private func setupToDoItem() {
        textView.text = todoItem?.text
        if let deadline = todoItem?.deadline {
            deadlineSwitch.setOn(true, animated: true)
            self.deadline = deadline
        }
        segmentControl.selectedSegmentIndex = 1
        if todoItem?.priority == .important {
            segmentControl.selectedSegmentIndex = 2
        } else if todoItem?.priority == .unimportant {
            segmentControl.selectedSegmentIndex = 0
        }
    }
    
    private func setupNavigationBar() {
        title = "Дело"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Сохранить", style: .done, target: self, action: #selector(saveTask))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Отменить", style: .plain, target: self, action: #selector(cancel))
    }
}

// MARK: Constraints
extension TaskViewController {
    private func setupConstraintForScrollView() {
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            constraintForScrollView
        ])
    }
    
    private func setupConstraintForTextView() {
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant:  16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant:  -16),
            textView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }
    
    private func setupConstraintForTableView() {
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
        ])
        constraintHideDatePicker.isActive = true
    }
    
    private func setupConstraintForDeleteButton() {
        NSLayoutConstraint.activate([
            deleteButtonView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            deleteButtonView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            deleteButtonView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 16),
            deleteButtonView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupConstraints() {
        setupConstraintForScrollView()
        setupConstraintForTextView()
        setupConstraintForTableView()
        setupConstraintForDeleteButton()
    }
}

// MARK: Targets
extension TaskViewController {
    @objc private func saveTask() {
        let priorityIndex = segmentControl.selectedSegmentIndex
        var priority = TodoItem.Priority.common
        if priorityIndex == 0 {
            priority = .unimportant
        } else if priorityIndex == 2 {
            priority = .important
        }
        let todoItem = TodoItem(id: "ID",
                                text: textView.text,
                                priority: priority,
                                deadline: deadline,
                                isCompleted: false,
                                dateOfCreation: Date.now,
                                dateOfChange: Date.now)
        fileCache.remove(task: todoItem)
        fileCache.addNew(task: todoItem)
        fileCache.saveAllItems(to: filename)
    }
    
    @objc private func cancel() {
        print("cancel")
    }
    
    @objc private func deleteTask(_ sender: UIButton) {
        guard let todoItem = todoItem else {
            return
        }
        fileCache.remove(task: todoItem)
        fileCache.saveAllItems(to: filename)
    }
    
    @objc private func addDeadline(_ sender: UISwitch) {
        if !sender.isOn {
            constraintShowDatePicker.isActive = false
            constraintHideDatePicker.isActive = true
            deadline = nil
        } else {
            deadline = Date.now + 86400
        }
        tableView.reloadData()
    }
    
    @objc private func changeDate(_ sender: UIDatePicker) {
        self.deadline = sender.date
        tableView.reloadData()
    }
}

// MARK: TextViewDelegate

extension TaskViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Что надо сделать?"
            textView.textColor = UIColor.lightGray
        }
    }
}

// MARK: Keyboard
extension TaskViewController {
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func kbWillShow(_ notification: Notification) {
        let userInfo = notification.userInfo
        let kbFrameSize = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        constraintForKeyboard = scrollView.heightAnchor.constraint(equalToConstant: view.bounds.height - kbFrameSize.height)
        constraintForScrollView.isActive = false
        constraintForKeyboard?.isActive = true
    }
    
    @objc private func kbWillHide() {
        constraintForKeyboard?.isActive = false
        constraintForScrollView.isActive = true
    }
}

// MARK: TableViewDataSource

extension TaskViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row != 2 {
            return Constants.sizeOfCell
        }
        
        return Constants.sizeOfDatePickerCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 2 {
            let cell = DatePickerCell()
            cell.datePicker.addTarget(self, action: #selector(changeDate(_:)) , for: .valueChanged)
            cell.datePicker.setDate(deadline ?? Date.now, animated: false)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            var content = cell.defaultContentConfiguration()
            if indexPath.row == 0 {
                cell.accessoryView = segmentControl
                content.text = "Важность"
            } else if indexPath.row == 1 {
                cell.accessoryView = deadlineSwitch
                content.text = "Сделать до"
                if deadlineSwitch.isOn {
                    if let deadline = deadline {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .none
                        
                        let date = dateFormatter.string(from: deadline)
                        content.secondaryText = "\(date)"
                        var property = content.secondaryTextProperties
                        if UITraitCollection.current.userInterfaceStyle == .dark {
                            property.color = UIColor(red: 0.04, green: 0.52, blue: 1.0, alpha: 1.0)
                        } else {
                            property.color = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
                        }
                        property.font = UIFont.systemFont(ofSize: 13)
                        content.secondaryTextProperties = property
                    }
                }
            }
            if UITraitCollection.current.userInterfaceStyle == .dark {
                cell.backgroundColor = UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
            }
            cell.contentConfiguration = content
            return cell
        }
    }
}

// MARK: Появление DatePicker
extension TaskViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if deadlineSwitch.isOn {
            if indexPath.row == 1  {
                constraintHideDatePicker.isActive.toggle()
                constraintShowDatePicker.isActive.toggle()
                if constraintShowDatePicker.isActive {
                    scrollView.contentSize.height += Constants.sizeOfDatePickerCell
                } else {
                    scrollView.contentSize.height -= Constants.sizeOfDatePickerCell
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: DatePickerCell
class DatePickerCell: UITableViewCell {
    lazy var containerView: UIView = .init()
    
    lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.preferredDatePickerStyle = .inline
        return picker
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        containerView.addSubview(datePicker)
        contentView.addSubview(containerView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let containerWidth = contentView.bounds.width
        
        datePicker.frame = .init(x: 0,
                                 y: 0,
                                 width: containerWidth,
                                 height: 320)
        
        containerView.frame = .init(x: 0,
                                    y: 0,
                                    width: containerWidth,
                                    height: 295)
    }
}
