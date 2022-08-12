import UIKit

class TaskViewController: UIViewController {

    private enum Constants {
        static let sizeOfDatePickerCell: CGFloat = 295
        static let sizeOfCell: CGFloat = 60
        static let cornerRadius: CGFloat = 20
        static let cellIdentifier = "Cell"
        static let separatorInset: CGFloat = 10
    }

    private var deadline: Date?

    weak var delegate: TasksListViewContollerDelegate?

    var todoItem: TodoItem?

    private lazy var constraintHideDatePicker = tableView.heightAnchor.constraint(equalToConstant: Constants.sizeOfCell * 2 - 5)
    private lazy var constraintShowDatePicker = tableView.heightAnchor.constraint(equalToConstant: Constants.sizeOfCell * 2 - 5 + Constants.sizeOfDatePickerCell)

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
        textView.backgroundColor = .backgroundGray
        textView.sizeToFit()
        textView.layer.borderWidth = 0
        textView.layer.cornerRadius = Constants.cornerRadius
        textView.delegate = self
        return textView
    }()

    private lazy var deleteButtonView: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = Constants.cornerRadius
        button.backgroundColor = .backgroundGray
        button.addTarget(self, action: #selector(deleteTask), for: .touchDown)
        button.setTitle("Удалить", for: .normal)
        button.setTitleColor(.redApp, for: .normal)
        return button
    }()

    private lazy var deadlineSwitch: UISwitch = {
        let mySwitch = UISwitch()
        mySwitch.addTarget(self, action: #selector(addDeadline(_:)), for: .valueChanged)
        return mySwitch
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: Constants.separatorInset, bottom: 0, right: Constants.separatorInset)
        tableView.layer.cornerRadius = Constants.cornerRadius
        tableView.tableFooterView = UIView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isScrollEnabled = false
        return tableView
    }()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.showsHorizontalScrollIndicator = false
        return scroll
    }()

    private lazy var segmentControl: UISegmentedControl = {
        let segment = UISegmentedControl(items: ["↓", "нет", "‼️"])
        segment.frame.size = .init(width: 150, height: 36)
        return segment
    }()

    private lazy var hideKeyboardTapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(oneTapped)
        )
        tapRecognizer.numberOfTapsRequired = 2
        return tapRecognizer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupToDoItem()
        setupNavigationBar()
        setupView()
        setupConstraints()
        scrollView.addGestureRecognizer(hideKeyboardTapRecognizer)
        registerForKeyboardNotifications()

    }

    override func viewDidLayoutSubviews() {
        scrollView.contentSize = .init(width: view.bounds.width, height: deleteButtonView.bounds.height + tableView.bounds.height + textView.bounds.height + 100)
    }
}

// MARK: Первоначальные настройки
extension TaskViewController {
    private func setupView() {
        view.backgroundColor = .background
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

        segmentControl.selectedSegmentIndex = todoItem?.priority == .unimportant ? 0 : todoItem?.priority == .important ? 2 : 1
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
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupConstraintForTextView() {
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            textView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }

    private func setupConstraintForTableView() {
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16)
        ])
        constraintHideDatePicker.isActive = true
    }

    private func setupConstraintForDeleteButton() {
        NSLayoutConstraint.activate([
            deleteButtonView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            deleteButtonView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
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
    @objc private func oneTapped() {
        textView.resignFirstResponder()
    }

    @objc private func saveTask() {
        let priorityIndex = segmentControl.selectedSegmentIndex
        let priority: TodoItem.Priority = priorityIndex == 1 ? .common : priorityIndex == 0 ? .unimportant : .important
        let dateOfCreation = todoItem?.dateOfCreation
        let todoItem = TodoItem(id: todoItem?.id ?? UUID().uuidString,
                                text: textView.text,
                                priority: priority,
                                deadline: deadline,
                                isCompleted: todoItem?.isCompleted ?? false,
                                dateOfCreation: dateOfCreation ?? Date.now,
                                dateOfChange: Date.now)
        delegate?.update(item: todoItem)
        self.dismiss(animated: true)
    }

    @objc private func cancel() {
        self.dismiss(animated: true)
    }

    @objc private func deleteTask(_ sender: UIButton) {
        guard let todoItem = todoItem else {
            return
        }
        delegate?.delete(item: todoItem)
        self.dismiss(animated: true)
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
        guard let kbFrameSize = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        scrollView.contentInset.bottom = UIDevice.current.orientation == .portrait ? kbFrameSize.height : -kbFrameSize.height + tableView.bounds.height + deleteButtonView.bounds.height
    }

    @objc private func kbWillHide() {
        scrollView.contentInset = UIEdgeInsets.zero
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
            cell.datePicker.addTarget(self, action: #selector(changeDate(_:)), for: .valueChanged)
            cell.datePicker.setDate(deadline ?? Date.now, animated: false)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
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
                        property.color = .blueApp
                        property.font = UIFont.systemFont(ofSize: 13)
                        content.secondaryTextProperties = property
                    }
                }
            }
            cell.contentConfiguration = content
            return cell
        }
    }
}

// MARK: Появление DatePicker
extension TaskViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .backgroundGray
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if deadlineSwitch.isOn {
            if indexPath.row == 1 {
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
    private enum Constants {
            static let datePickerHeight: CGFloat = 320
            static let conteinerViewHeight: CGFloat = 295
        }

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
                                     height: Constants.datePickerHeight
            )

            containerView.frame = .init(x: 0,
                                        y: 0,
                                        width: containerWidth,
                                        height: Constants.conteinerViewHeight)
    }
}
