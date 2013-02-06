/**
 * Created with JetBrains RubyMine.
 * User: MAB
 * Date: 2/6/13
 * Time: 10:25 PM
 * To change this template use File | Settings | File Templates.
 */

function missingInfoWarning(missing) {
    var answer = confirm ("You have not entered a:\n\n" + missing + "\nWould you still like to leave this page?")
    if (answer)
    window.location='/edits/index';
}

