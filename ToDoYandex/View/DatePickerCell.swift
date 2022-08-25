import UIKit

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
