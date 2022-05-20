import React, {useEffect, useState} from 'react';

function Transfer() {

    const [sources, setSources] = useState([]);
    const [destinations, setDestinations] = useState([]);
    const [transferDate, setTransferDate] = useState("");
    const [recipient, setRecipient] = useState("");
    const [sender, setSender] = useState("");
    const [amount, setAmount] = useState(0);
    const [memo, setMemo] = useState("");

    const [error, setError] = useState(null);
    const [responseData, setResponseData] = useState("");

    // Load source and destination accounts
    useEffect( async () => {

        const getAvailableAccounts = async () => {
            let options = {};
            await fetch(`${process.env.REACT_APP_API_EP}/api/account/transfer`, options)
                .then( res => res.json() )
                .then( data => {
                    setSources(data.sources);
                    setDestinations(data.destinations);
                })
                .catch( err => {
                    setError(err);
                })
        }

        await getAvailableAccounts();
    }, []);

    let handleSubmit = async () => {
        let data = JSON.stringify({
            transferDate: transferDate,
            recipient: recipient,
            sender: sender,
            amount: amount,
            memo: memo
        })

        let options = {
            method: "POST",
            headers: {
                'Content-Type': 'application/json'
            },
            body: data
        }

        await fetch(`${process.env.REACT_APP_API_EP}/api/transfer`, options)
            .then( res => {
                return res.json();
            })
            .then( data => {
                setResponseData(data);
            })
            .catch( err => {
                setError(err);
                setResponseData(err);
            })
    }

    let handleTransferDateChange = e => { setTransferDate(e.target.value )}
    let handleRecipientChange = e => { setRecipient(e.target.value )}
    let handleSenderChange = e => { setSender(e.target.value )}
    let handleAmountChange = e => { setAmount(e.target.value )}
    let handleMemoChange = e => { setMemo(e.target.value )}

    let source_options = () => {

        if (sources && sources.length) {
            let options = [<option className={"option"} value={null} key={-1}>Select a bank account as a source</option>];
            let items = sources.map( (source, index) => <option className={"option"} value={source.accountId} key={index}>{source.accountName}</option>)
            return [...options, ...items];
        }
        return <option className={"option"} value={null} disabled={true}>No bank accounts are available as a source</option>;

    }

    let destination_options = () => {

        if (destinations && destinations.length) {
            let options = [<option className={"option"} value={null} key={-1}>Select a bank account as a destination</option>];
            let items = destinations.map( (destinations, index) => <option className={"option"} value={destinations.recordId} key={index}>{destinations.accountName}</option>)
            return [...options, ...items];
        }
        return <option className={"option"} value={null} disabled={true}>No bank accounts are available as a destination</option>;
    }

    return (
        <div className={"container flex flex-row transfer-block"}>
            <div className={"flex flex-row rows"}>


                <div className={"fields form flex-grow-3"}>
                    <div id={"transfer"} className={"flex flex-col"}>

                        <h4 className={"title"}>Transfer Money</h4>

                        <div className={"transfer sender field flex flex-col"}>
                            <label htmlFor={"app-transfer-source"}>Transfer from</label>
                            <select id={"app-transfer-source"} className={"app-field"} required={true} onChange={ handleSenderChange } value={sender}>
                                {source_options()}
                            </select>
                        </div>

                        <div className={"transfer recipient field flex flex-col"}>
                            <label htmlFor={"app-transfer-source"}>Transfer to</label>
                            <select id={"app-transfer-source"} className={"app-field"} required={true} onChange={ handleRecipientChange } value={recipient}>
                                {destination_options()}
                            </select>
                        </div>

                        <div className={"transfer date field flex flex-col"}>
                            <label htmlFor={"app-transfer-date"}>Scheduled Date of Transfer</label>
                            <input type={"date"} id={"app-transfer-date"} className={"app-field"} required={true} onChange={ handleTransferDateChange } value={transferDate}/>
                        </div>

                        <div className={"amount amount field flex flex-col"}>
                            <label htmlFor={"app-transfer-amount"}><strong>Amount</strong></label>
                            <div className={"flex flex-row amount-with-currency"}>
                                <span className={"currency"}>$</span>
                                <input type={"number"} id={"app-transfer-amount"} className={"app-field flex-grow-9"} required={true} onChange={ handleAmountChange } value={amount}/>
                            </div>
                        </div>

                        <div className={"memo memo field flex flex-col"}>
                            <label htmlFor={"app-transfer-memo"}>Memo <em>(Optional)</em></label>
                            <input type={"text"} placeholder={"car, bills, loan, etc."} id={"app-transfer-memo"} className={"app-field"} onChange={ handleMemoChange } value={memo}/>
                        </div>
                        <div className={"actions flex flex-col"}>
                            <input type={"submit"} className={"submit app-button"} value={"Submit Transfer"} onClick={ handleSubmit }/>
                        </div>
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