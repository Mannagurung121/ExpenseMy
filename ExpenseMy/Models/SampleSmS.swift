//
//  SampleSmS.swift
//  ExpenseMy
//
//  Created by Manan Gurung on 06/05/26.
//

import Foundation

struct SampleSMS {
    
    let bankName: String
    let sms: String
    
}
    let sampleSMSList: [SampleSMS] = [
        
        SampleSMS(
            bankName: "SBI",
            sms: "Your A/c no. XXXXXX1234 is debited by Rs.450.00 on 06-05-26. Info: UPI-SWIGGY Ref No 123456789."
        ),
        
        SampleSMS(
            bankName: "HDFC",
            sms: "Rs.1200.00 debited from your HDFC Bank a/c XX9876 on 05/05/2026 to VPA zomato@paytm."
        ),
        
        SampleSMS(
            bankName: "ICICI",
            sms: "ICICI Bank Acct XX5678 debited Rs 850.00 on 05-May-26 transfer to Airtel."
        ),
        
        SampleSMS(
            bankName: "Kotak",
            sms: "Spent Rs.199.00 on your Kotak Debit Card at NETFLIX on 05/05/2026."
        ),
        
        SampleSMS(
            bankName: "Credit",
            sms: "Rs.500.00 credited to your SBI A/c XX1234 on 05-05-26 by UPI from paytm@paytm."
        )
    ]
    
    

