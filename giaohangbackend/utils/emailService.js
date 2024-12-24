import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'hienxadoi2020@gmail.com', // Replace with your email
    pass: 'awhm hoti qatg qihf' // Replace with your app password
  }
});

export const sendOTP = async (email, otp) => {
  const mailOptions = {
    from: 'Delivery Service',
    to: email,
    subject: 'Email Verification OTP to register',
    text: `Your OTP for email verification is: ${otp}`
  };

  return await transporter.sendMail(mailOptions);
};
