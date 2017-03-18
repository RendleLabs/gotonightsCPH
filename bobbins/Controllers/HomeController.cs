using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace bobbins.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }

        public IActionResult About()
        {
            ViewData["Message"] = "RendleLabs - we learn the hard way so you don't have to.";

            return View();
        }

        public IActionResult Contact()
        {
            ViewData["Message"] = "RendleLabs - we learn the hard way so you don't have to.";

            return View();
        }

        public IActionResult Error()
        {
            return View();
        }
    }
}
