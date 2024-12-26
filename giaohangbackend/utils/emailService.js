import nodemailer from 'nodemailer';

//đăng ký tài khoàn sử dụng dịch vụ gửi email của google
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'hienxadoi2020@gmail.com', 
    pass: 'awhm hoti qatg qihf' 
  }
});

//Form gửi email
export const sendOTP = async (email, otp) => {
  const mailOptions = {
    from: 'Delivery Service',
    to: email,
    subject: 'Email Verification OTP to register',
    text: `Your OTP for email verification is: ${otp}`
  };

  return await transporter.sendMail(mailOptions);
};

export const sendShipperStatusNotification = async (email, status, name) => {
  let subject = '';
  let text = '';

  if (status === 'approved') {
    subject = 'Shipper Registration Approved';
    text = `Dear ${name},\n\nCongratulations! Your shipper registration has been approved. You can now log in to your account and start delivering.\n\nBest regards,\nDelivery Service Team`;
  } else {
    subject = 'Shipper Registration Rejected';
    text = `Dear ${name},\n\nWe regret to inform you that your shipper registration has been rejected. Your account has been locked. If you believe this is a mistake or would like to appeal this decision, please contact our support team.\n\nBest regards,\nDelivery Service Team`;
  }

  const mailOptions = {
    from: 'Delivery Service',
    to: email,
    subject,
    text
  };

  return await transporter.sendMail(mailOptions);
};
