
const dummyAuthProvider = {
    isAuthenticated: false,

    signin(callback) {
        dummyAuthProvider.isAuthenticated = true;
        setTimeout(callback, 100);
    },

    signout(callback) {
        dummyAuthProvider.isAuthenticated = false;
        setTimeout(callback, 100);
    }
}

export {dummyAuthProvider};