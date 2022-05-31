import React, {useEffect, useState} from 'react';

function Transfer() {

    const BANKA = "banka";
    const BANKB = "bankb";
    const TRANSFER_A_B = "AB";
    const TRANSFER_B_A = "BA";
    const DEFAULT_TRANSFER = TRANSFER_A_B;
    const API_EP_TRANSFER_FUNDS = "/api/transfer/transferfunds";

    const [sources, setSources] = useState([]);
    const [destinations, setDestinations] = useState([]);
    const [transferDate, setTransferDate] = useState("");
    const [recipient, setRecipient] = useState("");
    const [recipientBank, setRecipientBank] = useState("");
    const [sender, setSender] = useState("");
    const [senderBank, setSenderBank] = useState("");
    const [amount, setAmount] = useState(0);
    const [memo, setMemo] = useState("");

    const [error, setError] = useState(null);
    const [responseData, setResponseData] = useState("");

    // Load source and destination accounts
    useEffect( async () => {

        // const getAvailableAccounts = async () => {
        //     let options = {};
        //     await fetch(`${process.env.REACT_APP_API_EP}/api/account/transfer`, options)
        //         .then( res => res.json() )
        //         .then( data => {
        //             setSources(data.sources);
        //             setDestinations(data.destinations);
        //         })
        //         .catch( err => {
        //             setError(err);
        //         })
        // }
        //
        // await getAvailableAccounts();
        setChangeOfTransfers(DEFAULT_TRANSFER)
    }, []);

    let handleSubmit = async e => {
        e.preventDefault();

        let data = JSON.stringify({
            transferDate: transferDate,
            fromBank: senderBank,
            fromAccount: sender,
            toBank: recipientBank,
            toAccount: recipient,
            amount: amount,
            memo: memo
        })

        const csrfToken = document.cookie.replace(/(?:(?:^|.*;\s*)XSRF-TOKEN\s*\=\s*([^;]*).*$)|^.*$/, '$1');

        let options = {
            method: "POST",
            headers: {
                'Content-Type': 'application/json',
                'X-XSRF-TOKEN': csrfToken
            },
            body: data
        }

        await fetch(API_EP_TRANSFER_FUNDS, options)
            .then( res => {
                return res.json();
            })
            .then( data => {
                setResponseData(JSON.stringify(data));
            })
            .catch( err => {
                setError(err);
                setResponseData(err);
            })
    }

    let setChangeOfTransfers = e => {
        let start = e === TRANSFER_A_B ? BANKA : BANKB;
        let end = e === TRANSFER_A_B ? BANKB : BANKA;

        setSenderBank(start);
        setRecipientBank(end);
    }

    let handleTransferDateChange = e => { setTransferDate(e.target.value )}
    let handleChangeOfTransfers = e => {
        setChangeOfTransfers(e.target.value);
    };
    let handleRecipientChange = e => { setRecipient(e.target.value )}
    let handleSenderChange = e => { setSender(e.target.value )}
    let handleAmountChange = e => { setAmount(e.target.value )}
    let handleMemoChange = e => { setMemo(e.target.value )}

    // let source_options = () => {
    //
    //     if (sources && sources.length) {
    //         let options = [<option className={"option"} value={null} key={-1}>Select a bank account as a source</option>];
    //         let items = sources.map( (source, index) => <option className={"option"} value={source.accountId} key={index}>{source.accountName}</option>)
    //         return [...options, ...items];
    //     }
    //     return <option className={"option"} value={null} disabled={true}>No bank accounts are available as a source</option>;
    //
    // }
    //
    // let destination_options = () => {
    //
    //     if (destinations && destinations.length) {
    //         let options = [<option className={"option"} value={null} key={-1}>Select a bank account as a destination</option>];
    //         let items = destinations.map( (destinations, index) => <option className={"option"} value={destinations.recordId} key={index}>{destinations.accountName}</option>)
    //         return [...options, ...items];
    //     }
    //     return <option className={"option"} value={null} disabled={true}>No bank accounts are available as a destination</option>;
    // }

    return (
        <div className={"container flex flex-row transfer-block"}>
            <div className={"flex flex-row rows"}>


                <div className={"fields form flex-grow-3"}>
                    <div id={"transfer"} className={"flex flex-col"}>

                        <h4 className={"title"}>Transfer Money</h4>

                        {/*<div className={"transfer sender field flex flex-col"}>*/}
                        {/*    <label htmlFor={"app-transfer-source"}>Transfer from</label>*/}
                        {/*    <select id={"app-transfer-source"} className={"app-field"} required={true} onChange={ handleSenderChange } value={sender}>*/}
                        {/*        {source_options()}*/}
                        {/*    </select>*/}
                        {/*</div>*/}

                        {/*<div className={"transfer recipient field flex flex-col"}>*/}
                        {/*    <label htmlFor={"app-transfer-source"}>Transfer to</label>*/}
                        {/*    <select id={"app-transfer-source"} className={"app-field"} required={true} onChange={ handleRecipientChange } value={recipient}>*/}
                        {/*        {destination_options()}*/}
                        {/*    </select>*/}
                        {/*</div>*/}


                        <form action={null} onSubmit={handleSubmit} >
                        <div className={"transfer date field flex flex-col"}>
                            <label htmlFor={"app-transfer-bank"}>Bank Transfer</label>
                            <select id={"app-transfer-bank"} className={"app-field"} required={true} onChange={ handleChangeOfTransfers } defaultValue={DEFAULT_TRANSFER}>
                                <option className={"option"} value={TRANSFER_A_B} key={TRANSFER_A_B}>Bank A to Bank B</option>
                                <option className={"option"} value={TRANSFER_B_A} key={TRANSFER_B_A}>Bank B to Bank A</option>
                            </select>
                        </div>

                        <div className={"transfer date field flex flex-col"}>
                            <label htmlFor={"app-sender"}>Transfer from Account</label>
                            <input type={"text"} id={"app-sender"} className={"app-field"} required={true} onChange={ handleSenderChange } value={sender}/>
                        </div>

                        <div className={"transfer date field flex flex-col"}>
                            <label htmlFor={"app-recipient"}>Transfer to Account</label>
                            <input type={"text"} id={"app-recipient"} className={"app-field"} required={true} onChange={ handleRecipientChange } value={recipient}/>
                        </div>

                        <div className={"amount amount field flex flex-col"}>
                            <label htmlFor={"app-transfer-amount"}><strong>Amount</strong></label>
                            <div className={"flex flex-row amount-with-currency"}>
                                <span className={"currency"}>$</span>
                                <input type={"number"} id={"app-transfer-amount"} className={"app-field flex-grow-9"} required={true} onChange={ handleAmountChange } value={amount}/>
                            </div>
                        </div>

                        {/* Metadata/Informational */}
                        <div className={"transfer date field flex flex-col"}>
                            <label htmlFor={"app-transfer-date"}>Scheduled Date of Transfer</label>
                            <input type={"text"} id={"app-transfer-date"} className={"app-field"} onChange={ handleTransferDateChange } value={transferDate}/>
                        </div>

                        <div className={"memo memo field flex flex-col"}>
                            <label htmlFor={"app-transfer-memo"}>Memo <em>(Optional)</em></label>
                            <input type={"text"} placeholder={"car, bills, loan, etc."} id={"app-transfer-memo"} className={"app-field"} onChange={ handleMemoChange } value={memo}/>
                        </div>
                        <div className={"actions flex flex-col"}>
                            <input type={"submit"} className={"submit app-button"} value={"Submit Transfer"} />
                        </div>

                        </form>
                    </div>
                </div>
                <div className={"guide flex-grow-6"}>
                    <h4 className={"title"}>Guide</h4>
                    <div className={"response flex flex-col"}>
                        <h5 className={"response-title"}>Response</h5>
                        <textarea placeholder={""} readOnly={true} value={responseData} className={"output"}/>
                    </div>
                </div>

            </div>
        </div>
    )
}

export default Transfer;